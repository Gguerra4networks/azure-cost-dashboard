# set-vars.ps1 - Azure Essentials Project 01: Cost Visibility Dashboard
# Run it with a dot and a space in front so the variables stay in your session:
#   . .\set-vars.ps1
# No passwords or secrets belong in this file.

$YOURNAME = "giovanni"
$LOCATION = "East US"

$RG       = "rg-cost-dashboard-$YOURNAME"
$LAW      = "law-cost-$YOURNAME"
$AG       = "ag-cost-alerts-$YOURNAME"
$LA       = "la-cost-alert-$YOURNAME"
$BUDGET   = "budget-cost-$YOURNAME"

Write-Host "Variables loaded:" -ForegroundColor Green
Write-Host "  YOURNAME = $YOURNAME"
Write-Host "  LOCATION = $LOCATION"
Write-Host "  RG       = $RG"
Write-Host "  LAW      = $LAW"
Write-Host "  AG       = $AG"
Write-Host "  LA       = $LA"
Write-Host "  BUDGET   = $BUDGET"
