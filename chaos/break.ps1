param(
    [Parameter(Mandatory)]
    [int]$Scenario
)

$Function = "bfl-lab-api"

switch ($Scenario) {
    1 {
        aws lambda put-function-concurrency --function-name $Function --reserved-concurrent-executions 0
    }
    default {
        Write-Host "Unknown scenario: $Scenario"
    }
}