#! /bin/sh

. pd-ca-lib.sh

CRMCORE_HOST=$1
PLAYER_ID=$2

VALID_CRM_ADAPTER_API_NAMES=(communication-preferences notifications notifications-preferences personal-info profile)
OAUTH=MyOAuthSessionToken123
PLAYER_ATTRIBUTES='1=2;500=2'

function get_ca_adapter_api()
{
  local HOST=$1
  local API=$2
  local PLAYER_ID=$3

  curl -s "http://${HOST}:8280/california-adapter/api/v1/players/self/${API}" \
  -H 'cache-control: no-cache'                  \
  -H 'content-type: application/json'           \
  -H 'connection: keep-alive'                   \
  -H "authorization: OAuth ${OAUTH}"            \
  -H "x-ex-system-id: ${CA_SYSTEM_ID}"          \
  -H "x-channel-id: ${CA_PWS_CHANNEL_ID}"       \
  -H "x-player-id: ${PLAYER_ID}"                \
  -H "x-player-attributes: ${PLAYER_ATTRIBUTES}"
}

for i in {0..4}; do 
  API=${VALID_CRM_ADAPTER_API_NAMES[$i]}
  get_ca_adapter_api $CRMCORE_HOST $API $PLAYER_ID
done
