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
    default {
        Write-Host "Unknown scenario: $Scenario"
    }
}