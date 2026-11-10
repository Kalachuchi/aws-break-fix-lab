# Incident 000: Unexpected WAF charges

**Symptom:** Free plan credits were being used even though no projects were actively running.

**Investigation:**
1. Checked Billing > Bills and expanded charges by service. All services were within free limits except WAF (~$1.30 MTD: web ACL $5/month + 3 rules at $1/month each, prorated).
2. Found one web ACL in WAF (scope: CloudFront Global) named `CreatedByCloudFront-...`.
3. Found a single CloudFront distribution in Disabled state with a placeholder S3 origin.
4. Checked CloudTrail event history (event source: cloudfront.amazonaws.com). Confirmed my own IAM user created the distribution and disabled it about a minute later.

**Root cause:** When the test CloudFront distribution was created, the "Enable security protections" option auto-created a WAF web ACL. Disabling the distribution stopped traffic charges, but WAF bills per web ACL and rule for as long as they exist.

**Fix:** Deleted the CloudFront distribution. The auto-created web ACL was removed along with it. Verified 0 distributions and 0 web ACLs remain.

**Prevention:**
- Delete test resources instead of only disabling them.
- Know which services bill for existence vs usage (WAF, NAT Gateway, Elastic IP, load balancers, running EC2).
- Updated the AWS Budget to exclude credits, so credit usage now triggers an alert.
