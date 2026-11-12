# 003: Lambda AccessDenied after moving to CloudFormation

## Symptom
After deploying the Lambda from the CloudFormation template, every request
failed. Invoking the function returned:

`AccessDeniedException: ... assumed-role/bfl-lab-lambda-role/bfl-lab-api is not authorized to perform: dynamodb:Scan on resource: ...table/bfl-incidents`

The stack itself showed `UPDATE_COMPLETE`, so the deploy looked successful.

## Investigation
1. The error named the table `bfl-incidents`, the old hand-made table.
   The stack's table is `bfl-lab-incidents`, so the function was talking
   to the wrong table.
2. Checked the Lambda configuration. The environment variable was correct:
   `TABLE_NAME = bfl-lab-incidents`.
3. Checked the stack's IAM role. It only allows `PutItem` and `Scan` on
   `bfl-lab-incidents`, which is correct (least privilege).
4. Downloaded the code that was actually deployed and read it with line
   numbers. It had two `table = ...` lines:
   ```python
   table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
   ...
   table = boto3.resource("dynamodb").Table("bfl-incidents")
   ```

## Root cause
When the code was changed to read the table name from `TABLE_NAME`, the old
hardcoded line was not removed. It ran second and overwrote `table`, so the
function used `bfl-incidents`. The new role has no access to that table, so
DynamoDB denied the request.

## Fix
1. Removed the old hardcoded line from `backend/lambda_function.py`.
2. Zipped the code again under a new name (`backend-v2.zip`), uploaded it to
   the artifacts bucket and updated `S3Key` in the template.
   Reusing the same file name would not work: CloudFormation only compares
   the template text, so it would see no change and skip the update.
3. Updated the stack, then confirmed GET returned 200 and POST returned 201.

## Prevention
- When replacing a line, delete the old one. Check the full diff before
  deploying (`git diff`).
- Use `aws cloudformation package`, which names each zip by a hash of its
  contents, so changed code always triggers an update.
- Test the function right after every deploy. A successful stack update does
  not mean the app works.
- Least privilege worked here: the narrow role blocked access to the wrong
  table instead of letting the bug go unnoticed.
