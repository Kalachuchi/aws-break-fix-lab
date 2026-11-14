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
    default {
        Write-Host "Unknown scenario: $Scenario"
    }
}