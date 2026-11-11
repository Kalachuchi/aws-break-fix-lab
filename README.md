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

## Status
In progress.

- [x] Working app: DynamoDB, Lambda, API Gateway, S3 + CloudFront
- [ ] CloudFormation (one command to deploy or reset)
- [ ] Break scenarios + randomizer
- [ ] EC2 + Linux scenarios
- [ ] Cognito login, delete, and resolve
