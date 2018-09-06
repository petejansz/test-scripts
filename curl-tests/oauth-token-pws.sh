HOST=$1
AUTHCODE=$1

curl -X POST \
  "https://$HOST/api/v1/oauth/self/tokens" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'x-channel-id: 2' \
  -H 'x-ex-system-id: 8' \
  -H 'x-site-id: 35' \
  -d '{
  "authCode" : "${AUTHCODE}",
  "clientId" : "SolSet2ndChancePortal",
  "siteId" : "35"
}'