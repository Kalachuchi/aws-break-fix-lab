# 004: Incident list empty, API returns 503

## Symptom
The page loads and the form shows, but the incident list is empty.
In the browser (F12 > Network), `GET /incidents` returned:

`{"message":"Service Unavailable"}` (HTTP 503)

## Investigation
1. Checked the Network tab and confirmed the API returned 503, so the problem
   was in the backend, not the page.
2. Went to CloudWatch Logs (`/aws/lambda/bfl-lab-api`). No new log entries
   since the day before, so the requests never reached the Lambda code.
3. Went to Lambda > Monitor. The **Throttles** metric jumped to 1-4 per minute,
   matching my page refreshes, so Lambda was refusing the requests.
4. Checked Lambda > Configuration > Concurrency. **Reserved concurrency was 0.**
5. Checked CloudTrail Event history (resource name `bfl-lab-api`):
   `PutFunctionConcurrency` by user `kala` at 2026-11-13 15:44:39 UTC.

## Root cause
Reserved concurrency was set to 0, so Lambda could run zero copies of the
function and throttled every request. API Gateway returned 503 to the site.
The frontend does not check for errors on GET, so the list showed up empty
instead of showing an error.

## Fix
Changed concurrency to **Use unreserved account concurrency** (no limit).
Confirmed the API returned 200 and the incident list loaded again.
CloudTrail showed the fix as `DeleteFunctionConcurrency` at 2026-11-13 16:01:23 UTC
(outage about 17 minutes).

## Prevention
- Add a CloudWatch alarm on the Lambda **Throttles** metric (> 0), so the
  problem is caught before a customer reports it.
- Use CloudTrail to check recent changes first when "nothing changed".
- Limit who can change concurrency in IAM (`lambda:PutFunctionConcurrency`).
- Make the frontend show an error message when the list fails to load,
  instead of a blank list.
