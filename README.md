# certbot-runner
A containerised deployment of certbot, suitable for running in Azure Container Instances that automatically updates Key Vault with latest certificate from Lets Encrypt and rotates Azure Front Door endpoints to use the latest certificate

## Environment Variables

```
DOMAIN="*.example.com,example.com"
EMAIL="example@example.com"
VAULT_NAME="kv-example"
FRONT_DOOR_NAME="fd-example"
FRONT_DOOR_ENDPOINTS="example-com,www-example-com"
```

## Running in ACI

```
DOMAIN="*.example.com,example.com"
EMAIL="example@example.com"
VAULT_NAME="kv-example"
FRONT_DOOR_NAME="fd-example"
FRONT_DOOR_ENDPOINTS="example-com,www-example-com"

RESOURCE_GROUP="rg-example"
NAME="example-certbot-runner"
IDENTITY_ID=/subscriptions/_SUBSCRIPTION_ID_/resourceGroups/_RESOURCE_GROUP_/providers/Microsoft.ManagedIdentity/userAssignedIdentities/_USER_ASSIGNED_IDENTITY_ID_

az container create \
    --resource-group $RESOURCE_GROUP \
    --name $NAME \
    --image ghcr.io/azurecitadel/certbot-runner/certbot-runner:latest \
    --restart-policy Never \
    --environment-variables 'DOMAIN'="'$DOMAIN'" 'EMAIL'="'$EMAIL'" 'VAULT_NAME'="'$VAULT_NAME'" 'FRONT_DOOR_NAME'="'$FRONT_DOOR_NAME'" 'FRONT_DOOR_ENDPOINTS'="'$FRONT_DOOR_ENDPOINTS'" \
    --assign-identity $IDENTITY_ID
```
