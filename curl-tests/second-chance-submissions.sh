curl -X GET \
  https://mobile-cat.calottery.com/api/v1/second-chance/players/self/submissions \
  -H 'authorization: OAuth pQ-Fi9RKHNUEh-PC1s2g4A' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'x-channel-id: 3' \
  -H 'x-device-uuid: 1234-5678-abcd-efgh' \
  -H 'x-esa-api-key: DBRDtq3tUERv79ehrheOUiGIrnqxTole' \
  -H 'x-ex-system-id: 8' \
  -H 'x-site-id: 35' \
  -d '{
  "authCode" : "eyJleHBpcmVzIjoxNDYyODg5MzMyODUzLCJyYW5kb20iOiJkMzMxYjkwYS0wZTE3LTQ3ZTctYTE2Ny1kMzEyM2UwNjBlZTMiLCJ2ZXJzaW9uIjoiMS4wIn0",
  "clientId" : "SolSet2ndChancePortal",
  "siteId" : "35"
}'