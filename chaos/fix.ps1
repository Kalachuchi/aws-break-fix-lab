param(
    [Parameter(Mandatory)]
    [int]$Scenario
)

$Function = "bfl-lab-api"

switch ($Scenario) {
    1 {
        aws lambda delete-function-concurrency --function-name $Function
    }
    2 {
        aws lambda update-function-configuration --function-name $Function --environment "Variables={TABLE_NAME=bfl-lab-incidents}"
    }
    3 {
        # Look up the IDs instead of hardcoding them (keeps the account ID out of the repo)
        $Sid = aws cloudformation describe-stack-resource --stack-name bfl-lab --logical-resource-id ApiInvokePermission --query StackResourceDetail.PhysicalResourceId --output text
        $ApiId = aws cloudformation describe-stack-resource --stack-name bfl-lab --logical-resource-id HttpApi --query StackResourceDetail.PhysicalResourceId --output text
        $Account = aws sts get-caller-identity --query Account --output text
        aws lambda add-permission --function-name $Function --statement-id $Sid --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:${Account}:${ApiId}/*"
    }
    default {
        Write-Host "Unknown scenario: $Scenario"
    }
}