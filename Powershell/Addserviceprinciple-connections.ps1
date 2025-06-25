$servicePrincipalDisplayName = "github-deployer" 

# The name of your target Resource Group.
# Example: "rg-uks-webapps"
$resourceGroupName = "rg-uks-connections" 

# Get the App ID (client ID) of the Service Principal by its display name.
# Any errors (e.g., SP not found) will be output by az CLI directly.
$servicePrincipalAppId = az ad sp list --display-name $servicePrincipalDisplayName --query "[0].appId" -o tsv

# Get the full Azure Resource ID of the target Resource Group.
# Any errors (e.g., RG not found) will be output by az CLI directly.
$resourceGroupId = az group show --name $resourceGroupName --query id -o tsv

# Assign the 'Contributor' role to the Service Principal for the specified Resource Group.
# Azure CLI will output success or failure messages directly to the console.
az role assignment create `
    --assignee $servicePrincipalAppId `
    --role "Contributor" `
    --scope $resourceGroupId