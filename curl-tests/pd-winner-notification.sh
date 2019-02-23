#! /bin/sh

# Trigger a WinnerNotification ("IMPORTANT MESSAGE") email

if [[ $# != 3 ]]; then
  echo "Trigger a WinnerNotification ("IMPORTANT MESSAGE") email"
  echo "USAGE: $(basename $0) crm-core-host email-username playerid"
  exit 1
fi

PDCORE=$1
EMAIL=$2
PLAYER_ID=$3

curl -sX POST "http://${PDCORE}:8280/california-adapter/api/v1/notifications" \
  -H "content-type: application/json" \
  -H "x-channel-id: 2" \
  -H "x-client-id: Portal" \
  -H "x-ex-system-id: 8" \
  -H "x-site-id: 35" \
  -H "x-player-id: ${PLAYER_ID}" \
  -d "{ \"playerId\": \"${PLAYER_ID}\", \"emailName\": \"${EMAIL}\", \"description\": \"unknown_description\", \"includeFooter\": false, \"templateParameters\": {}, \"eventTypeName\": \"WinnerNotification\"}"


