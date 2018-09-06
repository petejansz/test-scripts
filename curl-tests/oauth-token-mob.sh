# BDC mobile: ca-mobile.lotteryservices.com
HOST=$1
AUTH_CODE=$2

curl -X POST \
  "https://$HOST/api/v1/oauth/self/tokens" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'x-channel-id: 3' \
  -H 'x-esa-api-key: DBRDtq3tUERv79ehrheOUiGIrnqxTole' \
  -H 'x-ex-system-id: 8' \
  -H 'x-site-id: 35'  \
  -H 'X-ClientIP: 11.22.33.44' \
  -d "{ \"authCode\" : \"${AUTH_CODE}\", \"clientId\" : \"CAMOBILEAPP\", \"siteId\" : \"35\" }"
