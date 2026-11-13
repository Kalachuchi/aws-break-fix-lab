param(
    [Parameter(Mandatory)]
    [int]$Scenario
)

$Function = "bfl-lab-api"

switch ($Scenario) {
    1 {
        aws lambda delete-function-concurrency --function-name $Function
    }
    default {
        Write-Host "Unknown scenario: $Scenario"
    }
}