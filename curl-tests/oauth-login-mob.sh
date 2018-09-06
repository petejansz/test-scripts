# BDC mobile: ca-mobile.lotteryservices.com
HOST=$1

curl -X POST \
  "https://$HOST/api/v1/oauth/login" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'x-channel-id: 3' \
  -H 'x-esa-api-key: DBRDtq3tUERv79ehrheOUiGIrnqxTole' \
  -H 'x-ex-system-id: 8' \
  -H 'x-site-id: 35' \
  -d '{ "siteId":"35", "clientId":"CAMOBILEAPP", "resourceOwnerCredentials": { "USERNAME":"test22@yopmail.com", "PASSWORD":"RegTest6100" } }'
