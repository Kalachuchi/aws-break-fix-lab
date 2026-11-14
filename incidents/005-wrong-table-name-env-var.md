# 005: Incident list fails with 500 after a config change

## Symptom
The page loads, but the incident list shows
"Couldn't load incidents (500). Please try again later."
In the browser (F12 > Network), `GET /incidents` returned HTTP 500.

## Investigation
1. Confirmed the 500 in the Network tab, so the problem was in the backend.
2. Opened CloudWatch Logs (`/aws/lambda/bfl-lab-api`). Sorted streams by
   **Last event time**: there were two new streams, so new Lambda copies had
   started recently (a sign the function's config had changed).
3. The newest stream showed:
   `AccessDeniedException ... not authorized to perform: dynamodb:Scan on resource: ...table/bfl-lab-incidentz`
4. The real table is `bfl-lab-incidents`. The function was asking for a table
   with a typo (`incidentz`), which the role does not allow.
5. Checked Lambda > Configuration > Environment variables:
   `TABLE_NAME = bfl-lab-incidentz`.
6. Checked CloudTrail Event history (event name `UpdateFunctionConfiguration`):
   changed by user `kala` at 2026-11-14 17:18:39 UTC. CloudTrail also showed
   `AssumeRole` at 17:18:55 UTC, when a new Lambda copy picked up its role.

Note: the error is AccessDenied, not "table not found". IAM checks the
permission first and denies the request before DynamoDB looks for the table.

## Root cause
The `TABLE_NAME` environment variable was changed by hand to a wrong value
(`bfl-lab-incidentz`). The code reads the table name from this variable, so
every request went to a table the role is not allowed to use.

## Fix
Set `TABLE_NAME` back to `bfl-lab-incidents` in the Lambda console.
Confirmed the API returned 200 and the list loaded again.
CloudTrail showed the fix (`UpdateFunctionConfiguration`) at
2026-11-14 17:33:27 UTC (outage about 15 minutes).

## Prevention
- Change config through the CloudFormation template, not by hand. The value
  is set there with `!Ref IncidentsTable`, so it can't have a typo.
- Run CloudFormation **Detect drift** while investigating: `TABLE_NAME` is in
  the template, so a manual change shows as DRIFTED.
- When you see AccessDenied, check *which resource* it tried to reach before
  adding permissions. Widening the policy would hide the real bug.
- Note on timezones: CloudWatch Logs shows UTC, CloudTrail console shows local
  time. Convert everything to UTC for the timeline.
