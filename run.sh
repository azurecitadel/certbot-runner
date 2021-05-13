#!/bin/sh

# Must set:

echo "Generating certificates for '${DOMAIN}' informing '${EMAIL}' updating '${VAULT_NAME}' before adding to '${FRONT_DOOR_ENDPOINTS}' on '${FRONT_DOOR_NAME}'"

# Generate a cert request
generate_request () {
    certbot certonly -n \
        -d "${DOMAIN}" \
        -m "${EMAIL}" \
        --manual \
        --preferred-challenges=dns \
        --agree-tos \
        --config /usr/src/certbot/cli.ini \
        --manual-auth-hook /usr/src/certbot/auth-hook.sh \
        --manual-cleanup-hook /usr/src/certbot/cleanup.sh
}

# Keep trying to generate a certificate until we have one
generate_request
while [ $? -ne 0 ]
do
    sleep 5
    generate_request
done

# It is possible to pass in multiple domains in 1 env var, split by commas
# Ignore wildcard domains: https://certbot.eff.org/docs/using.html?highlight=domain#where-are-my-certificates
FIRST_DOMAIN=$(echo $DOMAIN | sed 's/\*\.//' | sed 's/,.*//')

CERTIFICATE_PATH="/usr/src/certbot/conf/live/${FIRST_DOMAIN}/fullchain.pem"
PRIVATE_KEY_PATH="/usr/src/certbot/conf/live/${FIRST_DOMAIN}/privkey.pem"
CERTIFICATE_NAME=$(echo $FIRST_DOMAIN | tr -d '.')

# Combine PEM and key in one pfx file (pkcs#12)
PFX_FILE="${CERTIFICATE_PATH}.pfx"
TEMP_PASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w24 | head -n 1)

openssl pkcs12 -export \
    -in $CERTIFICATE_PATH \
    -inkey $PRIVATE_KEY_PATH \
    -out $PFX_FILE \
    -passin pass:$TEMP_PASSWORD \
    -passout pass:$TEMP_PASSWORD

# Log in to Azure and add to Key Vault
ACCESS_TOKEN=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/' -H Metadata:true | jq -r '.access_token')

SUBSCRIPTION_ID=$(curl -s -X GET \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    https://management.azure.com/subscriptions?api-version=2016-06-01 | jq -r '.value[0].subscriptionId')

# Import Certificate into Key Vault
KV_ACCESS_TOKEN=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' -H Metadata:true | jq -r '.access_token')
CERTIFICATE_ID=$(curl -s -X POST \
    -H "Authorization: Bearer $KV_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"value\": \"$(base64 "${PFX_FILE}")\",\"pwd\": \"${TEMP_PASSWORD}\"}" \
    "https://${VAULT_NAME}.vault.azure.net/certificates/${CERTIFICATE_NAME}/import?api-version=7.0" | jq -r '.id')

# Manually rotate the Frontend TLS certificate to latest version from Key Vault
KEY_VAULT_ID=$(curl -s -X GET \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.KeyVault/vaults?api-version=2019-09-01" | jq -r ".value[] | select(.name==\"$VAULT_NAME\").id")

FRONT_DOOR_RG=$(curl -s -X GET \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Network/frontDoors?api-version=2018-08-01" | jq -r ".value[] | select(.name==\"$FRONT_DOOR_NAME\").id" | sed  "s/.*resourcegroups\/\(.*\)\/providers.*/\1/")

# Apply this latest certificate to each endpoint
for endpoint in ${FRONT_DOOR_ENDPOINTS//,/ }; do
    curl -s -X POST \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"certificateSource\": \"AzureKeyVault\",\"protocolType\": \"ServerNameIndication\",\"minimumTlsVersion\": \"1.2\",\"keyVaultCertificateSourceParameters\": {\"vault\": {\"id\": \"${KEY_VAULT_ID}\"},\"secretName\": \"${CERTIFICATE_NAME}\"}}" \
        "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${FRONT_DOOR_RG}/providers/Microsoft.Network/frontDoors/${FRONT_DOOR_NAME}/frontendEndpoints/${endpoint}/enableHttps?api-version=2020-05-01"
done
