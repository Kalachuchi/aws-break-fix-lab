# AWS Break & Fix Lab

A hands-on lab for practicing Cloud Support troubleshooting. I built a small app on AWS (a serverless web app plus an EC2 Linux server), break it on purpose the way real customers do, then diagnose and fix it using the same tools a support engineer would.

## The app: Incident Log
A simple web app for logging support cases (symptom, root cause, fix). It's also the app that gets broken.

## Architecture
| Part | AWS service |
|---|---|
| Website | S3 + CloudFront |
| API | API Gateway (HTTP API) + Lambda (Python) |
| Database | DynamoDB |
| Linux box | EC2 (only on while practicing) |
| Monitoring | CloudWatch + CloudTrail |
| Infrastructure as Code | CloudFormation |

## Folder structure
```
frontend/    Incident Log website (HTML/JS)
backend/     Lambda code (Python)
infra/       CloudFormation templates
chaos/       Scripts that break things on purpose
incidents/   Support-style write-ups, one per scenario
```

## Incidents
Sample incident reports
| # | Scenario | Services | Status |
|---|---|---|---|
| [000](incidents/000-unexpected-waf-charges.md) | Unexpected WAF charges from a disabled CloudFront distribution | Billing, WAF, CloudFront, CloudTrail | Resolved |
| [001](incidents/001-cors-error-on-localhost.md) | CORS error when testing the frontend on localhost | API Gateway, CloudFront | Resolved |
| [002](incidents/002-lambda-syntax-error-500.md) | API returns 500 after a Lambda code change | Lambda, CloudWatch Logs | Resolved |
| [003](incidents/003-lambda-accessdenied-hardcoded-table.md) | Lambda AccessDenied after moving to CloudFormation | Lambda, IAM, DynamoDB, CloudFormation | Resolved |
| [004](incidents/004-lambda-throttled-503.md) | Incident list empty, API returns 503 (Lambda throttled) | Lambda, CloudWatch, CloudTrail | Resolved |

## Deploy it yourself
The whole app is one CloudFormation stack (`infra/template.yaml`). You need the AWS CLI set up in `us-east-1`.

1. Make a bucket for the Lambda code (one time, the name must be unique):
   ```
   aws s3 mb s3://YOUR-ARTIFACT-BUCKET
   ```
2. Package and deploy the stack:
   ```
   aws cloudformation package --template-file infra/template.yaml --s3-bucket YOUR-ARTIFACT-BUCKET --output-template-file packaged.yaml
   aws cloudformation deploy --template-file packaged.yaml --stack-name bfl-lab --capabilities CAPABILITY_NAMED_IAM
   ```
3. Get the outputs (`ApiUrl`, `SiteUrl`, `SiteBucketName`):
   ```
   aws cloudformation describe-stacks --stack-name bfl-lab --query "Stacks[0].Outputs"
   ```
4. Set `API_URL` in `frontend/index.html` to your `ApiUrl`, then upload it:
   ```
   aws s3 cp frontend/index.html s3://YOUR-SITE-BUCKET/
   ```
5. Open your `SiteUrl`.

To remove everything: empty the site bucket, then `aws cloudformation delete-stack --stack-name bfl-lab`.

## Status
In progress.

- [x] Working app: DynamoDB, Lambda, API Gateway, S3 + CloudFront
- [x] CloudFormation (one command to deploy or reset)
- [ ] Break scenarios + randomizer
- [ ] EC2 + Linux scenarios
- [ ] Cognito login, delete, and resolve
