param(
    [Parameter(Mandatory)]
    [int]$Scenario
)

$Function = "bfl-lab-api"

switch ($Scenario) {
    1 {
        aws lambda put-function-concurrency --function-name $Function --reserved-concurrent-executions 0
    }
    2 {
        aws lambda update-function-configuration --function-name $Function --environment "Variables={TABLE_NAME=bfl-lab-incidentz}"
    }
    3 {
        # The statement ID has a random suffix, so ask the stack for it
        $Sid = aws cloudformation describe-stack-resource --stack-name bfl-lab --logical-resource-id ApiInvokePermission --query StackResourceDetail.PhysicalResourceId --output text
        aws lambda remove-permission --function-name $Function --statement-id $Sid
    }
    default {
        Write-Host "Unknown scenario: $Scenario"
    }
}