# 006: API returns 500, but Lambda shows no logs and no invocations

## Symptom
The page loads, but the incident list shows
"Couldn't load incidents (500). Please try again later."
In the browser (F12 > Network), `GET /incidents` returned HTTP 500.

## Investigation
1. Confirmed the 500 in the Network tab, so the problem was in the backend.
2. Checked CloudWatch Logs (`/aws/lambda/bfl-lab-api`), sorted by
   Last event time. The newest entry was from two days earlier, so the
   Lambda code never ran.
3. Checked Lambda > Monitor. **Invocations: no data. Throttles: no data.**
   - Not a throttle (that would show Throttles and return 503, see 004).
   - Not a code or IAM error inside the function (that would leave a log,
     see 005).
   - So the request never reached the function at all. The problem was
     between API Gateway and Lambda.
4. Checked Lambda > Configuration > Permissions > **Resource-based policy
   statements**. It was empty. API Gateway was no longer allowed to invoke
   the function.
5. Checked CloudTrail Event history (event source `lambda.amazonaws.com`):
   `DeleteResourcePolicy` by user `kala` at 2026-11-16 15:25:20 UTC.
   (The console's Delete button records `DeleteResourcePolicy`; the CLI's
   `remove-permission` records `RemovePermission`.)

## Root cause
The Lambda's resource-based policy was deleted. That policy is the
function's "guest list": it allows `apigateway.amazonaws.com` to call
`lambda:InvokeFunction`, but only from this API. Without it, Lambda rejected
API Gateway's call before running anything, so nothing was logged or counted,
and API Gateway returned 500.

## Fix
Added the permission back:

```
aws lambda add-permission --function-name bfl-lab-api --statement-id <statement-id> --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:ACCOUNT_ID:<api-id>/*"
```

Confirmed the API returned 200 and the list loaded again.
CloudTrail showed `AddPermission` at 2026-11-16 15:45:35 UTC
(outage about 20 minutes).

## Prevention
- Pattern to remember: **500 + no logs + no invocations + no throttles**
  means check the Lambda's resource-based policy first.
- Keep the permission in the CloudFormation template (`AWS::Lambda::Permission`)
  and redeploy or run Detect drift if it goes missing.
- Turn on API Gateway access logging to see the integration error on the API
  side (CloudWatch Logs, small cost).
- Limit who can call `lambda:RemovePermission` / `DeleteResourcePolicy` in IAM.
