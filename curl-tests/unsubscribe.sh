#!/bin/sh

PROTO=$1
HOST=$2
PROMO=$3
TOKEN=$(echo $4 | xargs)
DEFAULT_CURL_OPTS="-o /dev/null -s -w %{http_code}"

if [[ "$PROMO" == 'promo' ]]; then
    URL="${PROTO}://${HOST}/api/v1/players/notifications/promo/unsubscribe/${TOKEN}"
else
    URL="${PROTO}://${HOST}/api/v1/notifications/unsubscribe?token=${TOKEN}"
fi

echo $URL
curl $DEFAULT_CURL_OPTS -sX POST "${URL}" \
    --header 'Content-Type: application/json'   \
    --header 'X-EX-SYSTEM-ID: 8'    \
    --header 'X-CHANNEL-ID: 2'  \
    --header 'X-SITE-ID: 35'

echo