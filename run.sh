#!/bin/sh

# Generate a cert request
certbot certonly -n \
    -d "${DOMAIN}" \
    -m "${EMAIL}" \
    --manual \
    --preferred-challenges=dns \
    --agree-tos \
    --manual-auth-hook /usr/src/certbot/auth-hook.sh \
    --manual-cleanup-hook /usr/src/certbot/cleanup.sh

# It is possible to pass in multiple domains in 1 env var, split by commas
FIRST_DOMAIN=$(echo $DOMAIN | sed 's/,.*//')

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
az login --identity
az keyvault certificate import \
    --vault-name "${VAULT_NAME}" \
    -n "${CERTIFICATE_NAME}" \
    --password "${TEMP_PASSWORD}" \
    -f $PFX_FILE
