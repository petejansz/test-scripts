HOST=$1
USERNAME=$2
PASSWORD=$3

curl -sX POST \
  "https://$HOST/api/v1/oauth/login" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'x-channel-id: 2' \
  -H 'x-ex-system-id: 8' \
  -H 'x-site-id: 35' \
  -d "{\"siteId\":\"35\", \"clientId\":\"SolSet2ndChancePortal\", \"resourceOwnerCredentials\": {\"USERNAME\": \"${USERNAME}\", \"PASSWORD\": \"${PASSWORD}\" }}"