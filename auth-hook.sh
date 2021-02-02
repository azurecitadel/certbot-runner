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

echo "Adding $TXT to DNS zone $DNS_ZONE_NAME"

az network dns record-set txt create \
    -n "${TXT}" \
    -z "${DNS_ZONE_NAME}" \
    -g "${DNS_ZONE_RG}" \
    --ttl 30

az network dns record-set txt add-record \
    -n "${TXT}" \
    -z "${DNS_ZONE_NAME}" \
    -g "${DNS_ZONE_RG}" \
    -v "${CERTBOT_VALIDATION}"

sleep 10