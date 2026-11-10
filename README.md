# AWS Break & Fix Lab

A hands-on lab for practicing Cloud Support troubleshooting. I built a small serverless app on AWS, break it on purpose the way real customers do, then diagnose and fix it using the same tools a support engineer would.

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
| # | Scenario | Services | Status |
|---|---|---|---|
| 000 | Unexpected WAF charges from a disabled CloudFront distribution | Billing, WAF, CloudFront, CloudTrail | Resolved |

## Status
In progress.
