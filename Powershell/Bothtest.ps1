$servicePrincipalName = "github-deployer"

# Define your first resource group
$resourceGroup1 = "rg-uks-webapps"
# Define your second resource group - IMPORTANT: Replace with your actual second resource group name
$resourceGroup2 = "rg-uks-data" 

# --- 1. Create the Service Principal ---
$spOutput = az ad sp create-for-rbac `
    --name $servicePrincipalName `
    --role "Contributor" `
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup1" `
    --query "{appId: appId, password: password, tenant: tenant}" `
    | ConvertFrom-Json

# Extract the appId, password (client secret), and tenantId
$appId = $spOutput.appId
$password = $spOutput.password
$tenantId = $spOutput.tenant

# --- 2. Assign Contributor Role to First Resource Group ($resourceGroup1) ---
$resourceGroupId1 = (az group show --name $resourceGroup1 --query id -o tsv)
az role assignment create `
    --assignee $appId `
    --role "Contributor" `
    --scope $resourceGroupId1

# --- 3. Assign Contributor Role to Second Resource Group ($resourceGroup2) ---
$resourceGroupId2 = (az group show --name $resourceGroup2 --query id -o tsv)
az role assignment create `
    --assignee $appId `
    --role "Contributor" `
    --scope $resourceGroupId2