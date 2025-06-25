$servicePrincipalName = "github-deployer"
$resourceGroup = "rg-uks-webapps"

# --- 1. Create the Service Principal ---
$spOutput = az ad sp create-for-rbac `
    --name $servicePrincipalName `
    --role "Contributor" `
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup" `
    --query "{appId: appId, password: password, tenant: tenant}" `
    | ConvertFrom-Json

# Extract the appId and password (client secret)
$appId = $spOutput.appId
$password = $spOutput.password
$tenantId = $spOutput.tenant

# --- 2. Assign Contributor Role to Resource Group ---
az role assignment create `
    --assignee $appId `
    --role "Contributor" `
    --resource-group $resourceGroup

Write-Host "AppID: $appId, Secret: $password, Tenant ID: $tenantId"
# Important: Store the appId, tenantId, and password (client secret) securely.
# You will need these credentials for applications or services to authenticate using this Service Principal.