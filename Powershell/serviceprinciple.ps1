
$servicePrincipalName = "my-app-service-principal"

$resourceGroup1 = "rg-uks-webapps"
$resourceGroup2 = "rg-uks-connections"

# --- 1. Create the Service Principal ---
$spOutput = az ad sp create-for-rbac `
    --name $servicePrincipalName `
    --role "Contributor" `
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup1" `
    --query "{appId: appId, password: password, tenant: tenant}" `
    | ConvertFrom-Json

# Extract the appId and password (client secret)
$appId = $spOutput.appId
$password = $spOutput.password
$tenantId = $spOutput.tenant


# --- 2. Assign Contributor Role to Resource Group 1 ---
az role assignment create `
    --assignee $appId `
    --role "Contributor" `
    --resource-group $resourceGroup1
    --scopes $servicePrincipalName


# --- 3. Assign Contributor Role to Resource Group 2 ---
az role assignment create `
    --assignee $appId `
    --role "Contributor" `
    --resource-group $resourceGroup2
    --scopes $servicePrincipalName


# Important: Store the appId, tenantId, and password (client secret) securely.
# You will need these credentials for applications or services to authenticate using this Service Principal.
