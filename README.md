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
