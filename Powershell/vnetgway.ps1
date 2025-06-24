# Variables
$resourceGroup = "rg-uks-connections"
$location = "uksouth"

# Create resource group
az group create --name $resourceGroup --location $location

# Get current subscription
$subscription = az account show --query "name" -o tsv

Write-Host "Resource group '$resourceGroup' created in location '$location'."
Write-Host "Current Azure subscription: $subscription"
