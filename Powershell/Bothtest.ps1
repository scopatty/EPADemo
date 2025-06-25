$servicePrincipalName = "github-deployer"

# Define your first resource group
$resourceGroup1 = "rg-uks-webapps"
# Define your second resource group - IMPORTANT: Replace with your actual second resource group name
$resourceGroup2 = "rg-uks-data" 

# --- 1. Create the Service Principal ---
$spOutput = az ad sp create-for-rbac `  # ENSURE NO SPACE AFTER THIS BACKTICK
    --name $servicePrincipalName `     # ENSURE NO SPACE AFTER THIS BACKTICK
    --role "Contributor" `             # ENSURE NO SPACE AFTER THIS BACKTICK
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup1" ` # ENSURE NO SPACE AFTER THIS BACKTICK
    --query "{appId: appId, password: password, tenant: tenant}" ` # ENSURE NO SPACE AFTER THIS BACKTICK
    | ConvertFrom-Json

# Extract the appId, password (client secret), and tenantId
$appId = $spOutput.appId
$password = $spOutput.password
$tenantId = $spOutput.tenant

# --- 2. Assign Contributor Role to First Resource Group ($resourceGroup1) ---
$resourceGroupId1 = (az group show --name $resourceGroup1 --query id -o tsv)
az role assignment create `           # ENSURE NO SPACE AFTER THIS BACKTICK
    --assignee $appId `                # ENSURE NO SPACE AFTER THIS BACKTICK
    --role "Contributor" `             # ENSURE NO SPACE AFTER THIS BACKTICK
    --scope $resourceGroupId1

# --- 3. Assign Contributor Role to Second Resource Group ($resourceGroup2) ---
$resourceGroupId2 = (az group show --name $resourceGroup2 --query id -o tsv)
az role assignment create `           # ENSURE NO SPACE AFTER THIS BACKTICK
    --assignee $appId `                # ENSURE NO SPACE AFTER THIS BACKTICK
    --role "Contributor" `             # ENSURE NO SPACE AFTER THIS BACKTICK
    --scope $resourceGroupId2