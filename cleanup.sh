#!/bin/sh

az login --identity

DNS_ZONE_NAME="${CERTBOT_DOMAIN}"
if [ "$DNS_ZONE_NAME" = "" ]; then
    echo "DNS_ZONE_NAME ($DNS_ZONE_NAME) not found"
    exit 1
fi

DNS_ZONE_RG=$(az network dns zone list --query "[?name=='$DNS_ZONE_NAME'].resourceGroup" -o tsv)
if [ "$DNS_ZONE_RG" = "" ]; then
    echo "DNS_ZONE_RG ($DNS_ZONE_RG) not found"
    exit 1
fi

TXT="_acme-challenge.${CERTBOT_DOMAIN}"

echo "Removing $TXT from DNS zone $DNS_ZONE_NAME"

az network dns record-set txt delete \
    -n "${TXT}" \
    -z "${DNS_ZONE_NAME}" \
    -g "${DNS_ZONE_RG}" \
    -y
