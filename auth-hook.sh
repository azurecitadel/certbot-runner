#!/bin/sh

ACCESS_TOKEN=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/' -H Metadata:true | jq -r '.access_token')

SUBSCRIPTION_ID=$(curl -s -X GET \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    https://management.azure.com/subscriptions?api-version=2016-06-01 | jq -r '.value[0].subscriptionId')

DNS_ZONE_NAME="${CERTBOT_DOMAIN}"
if [ "$DNS_ZONE_NAME" = "" ]; then
    echo "DNS_ZONE_NAME ($DNS_ZONE_NAME) not found"
    exit 1
fi

DNS_ZONE_RG=$(curl -s -X GET \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Network/dnszones?\$top=1&api-version=2018-05-01" | jq -r ".value[] | select(.name==\"$DNS_ZONE_NAME\").id" | sed  "s/.*resourceGroups\/\(.*\)\/providers.*/\1/")
if [ "$DNS_ZONE_RG" = "" ]; then
    echo "DNS_ZONE_RG ($DNS_ZONE_RG) not found"
    exit 1
fi

TXT="_acme-challenge"
TTL=300

echo "Adding $TXT to DNS zone $DNS_ZONE_NAME"

curl -s -X PUT \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"properties\": {\"TTL\": $TTL, \"TXTRecords\": [{\"value\": [\"${CERTBOT_VALIDATION}\"]}]}}" \
    "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$DNS_ZONE_RG/providers/Microsoft.Network/dnsZones/$DNS_ZONE_NAME/TXT/$TXT?api-version=2018-05-01"
