HOST=$1
USERNAME='quiterascal@mailinator.com'

curl -X POST \
  "https://$HOST/api/v2/players" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'x-channel-id: 2' \
  -H 'x-ex-system-id: 8' \
  -H 'x-site-id: 35' \
  -d $(cat reg-user.json)
