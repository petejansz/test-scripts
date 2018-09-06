#!/usr/bin/sh

HOST=$1
USERNAME=$2
PASSWORD=$3

OAUTH=$(node ~pjansz/Documents/bin/pd-login.js -h $HOST -u $USERNAME -p $PASSWORD)

curl -X GET \
  "https://$HOST/api/v1/players/self/attributes" \
  -H "authorization: OAuth ${OAUTH}" \
  -H 'cache-control: no-cache' \
  -H 'x-device-uuid: 33333' 