# 001: API returns 500 after Lambda code change

## Symptom
The incident list stopped loading on the site. Calling the API directly
(`GET /incidents`) returned:

`{"message":"Internal Server Error"}` (HTTP 500)

Both listing and creating incidents failed.

## Investigation
1. Confirmed the problem by calling the API URL directly. It returned HTTP 500,
   so the issue was in the backend, not the frontend.
2. A 500 from API Gateway with a Lambda integration usually means the Lambda
   itself failed, so I checked the Lambda's logs.
3. Opened CloudWatch Logs, log group `/aws/lambda/bfl-incidents-api`.
4. Every request showed the same error:
   `Runtime.UserCodeSyntaxError: Syntax error in module 'lambda_function': invalid syntax (lambda_function.py, line 23)`
5. Line 23 was the new `"created_at"` field I had just added to the POST item.
6. Checked the line above it and found `"status": "open"` was missing a
   trailing comma.

## Root cause
A Python syntax error (missing comma in a dictionary) was deployed to the
Lambda. Python could not load the file at all, so every request failed,
even the GET route that had not changed.

The change was also made directly in the Lambda console instead of the repo,
so it was never checked before deploying.

## Fix
Added the missing comma after `"status": "open"`, redeployed the Lambda,
and confirmed `GET /incidents` returned HTTP 200 with the incident list.

## Prevention
- Make code changes in the repo first, then deploy. The console should not be
  the place where code is written.
- Check syntax before deploying (for example `python -m py_compile lambda_function.py`).
- After every deploy, test the API right away so errors are caught immediately.
- Later: automate deploys (CloudFormation) so code always comes from the repo.