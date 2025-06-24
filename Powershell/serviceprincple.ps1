# Variables
$resourceGroup = "rg-uks-webapps"
$spName = "http://sp-for-rg-uks-webapps"  # Service principal name (URI format)
$location = "uksouth"

# Create service principal with a generated password
$sp = az ad sp create-for-rbac --name $spName --role Contributor --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup" --query "{appId: appId, password: password}" -o json | ConvertFrom-Json

if ($sp -ne $null) {
    Write-Host "Service Principal created successfully."
    Write-Host "AppId (Client ID): $($sp.appId)"
    Write-Host "Password (Client Secret): $($sp.password)"
} else {
    Write-Host "Failed to create service principal."
}
