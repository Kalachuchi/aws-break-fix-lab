# 004: Incident list empty, API returns 503

**Services:** Lambda, API Gateway, CloudWatch (Logs + Metrics), CloudTrail
**Impact:** Incident list could not load for about 17 minutes. Logging new
incidents also failed (same function).

## Symptom
The page loads and the form shows, but the incident list is empty, with no
error message. From a customer's view: "all my incidents disappeared."

In the browser (F12 > Network), `GET /incidents` returned:

`{"message":"Service Unavailable"}` (HTTP 503)

The Console showed `TypeError: incidents.reverse is not a function`: the page
expected a list of incidents but got the error object, so the list was
cleared and nothing was drawn.

## Investigation
1. **Network tab:** confirmed the API returned 503. The page itself (200) and
   CloudFront were fine, so the problem was behind the API.
2. **First question: did the request reach the Lambda code?**
   Opened CloudWatch Logs (`/aws/lambda/bfl-lab-api`) and sorted streams by
   Last event time. The newest entry was from 2026-11-12 17:23 UTC, the day
   before. No new logs, so the code never ran. If the code had run and
   crashed, there would be an `[ERROR]` line.
3. **No logs usually means something stopped the request before the code.**
   Opened Lambda > Monitor (time range 1h). The **Throttles** metric jumped
   from 0 to 1-4 per minute starting around 15:44 UTC, matching my page
   refreshes (each page load sends one `GET /incidents`).
   Note: Lambda metrics can take 1-5 minutes to appear.
4. **Throttles mean "accepted but no capacity to run it".** Traffic was almost
   zero, so this was not real overload. That points to a limit on the
   function. Checked Lambda > Configuration > Concurrency:
   **Reserved concurrency = 0.**
5. **What changed, and when?** CloudTrail Event history, resource name
   `bfl-lab-api`:

| Time (UTC) | Event | User | Meaning |
|---|---|---|---|
| 2026-11-13 15:44:39 | `PutFunctionConcurrency` | kala | Concurrency set to 0 (the break) |
| 2026-11-13 16:01:23 | `DeleteFunctionConcurrency` | kala | Limit removed (the fix) |

   Note: the CloudTrail console shows local time (UTC+8). I first copied
   these times as UTC by mistake; converting them made them line up with the
   Throttles graph (15:44 UTC).

## Root cause
Reserved concurrency was set to 0 on `bfl-lab-api`.

Reserved concurrency is the maximum number of copies of a function that can
run at the same time. It also reserves that many from the account's shared
pool. At 0, Lambda can run zero copies, so it throttled every request.
API Gateway (HTTP API) turned the throttle into a 503 for the browser.

The frontend made it worse: the GET code did not check `res.ok`, so instead
of an error message the user saw an empty list.

### How this differs from similar errors
| Clue | This incident (throttle) | API Gateway throttling (429) | Code/IAM error (500) |
|---|---|---|---|
| Status code | 503 | 429 | 500 |
| Lambda logs | None | None | `[ERROR]` line |
| Lambda Throttles metric | Spike | None (stopped at the API) | None |

## Fix
Lambda > Configuration > Concurrency > Edit > **Use unreserved account
concurrency** (no limit). CLI equivalent:

```
aws lambda delete-function-concurrency --function-name bfl-lab-api
```

Verified:
- `GET /incidents` returned 200 and the list loaded again.
- Throttles went back to 0.
- CloudTrail recorded `DeleteFunctionConcurrency` at 16:01:23 UTC
  (outage about 17 minutes).

Follow-up fix: the frontend now checks `res.ok` on GET and shows
"Couldn't load incidents (503)" (or a 429 message) instead of a blank list.

## Prevention
- **Alert on throttles:** a CloudWatch alarm on the Lambda `Throttles`
  metric (> 0) would catch this before a customer reports it.
- **Check CloudTrail early:** when "nothing changed", Event history shows
  config changes (who, what, when) in minutes.
- **Limit who can change it:** restrict `lambda:PutFunctionConcurrency` in IAM.
- **Fail visibly:** the frontend should always show an error state, never an
  empty page.
- **Know the pattern:** 503 + no logs + Throttles spike = check concurrency.

## Lessons learned
- No logs does not mean nothing happened. Some failures only show up in
  **Metrics**.
- Reserved concurrency is both a guarantee and a cap. 0 works as an
  emergency off switch, which is why it can be left on by accident.
- Always write times in UTC and check which timezone each console shows.
