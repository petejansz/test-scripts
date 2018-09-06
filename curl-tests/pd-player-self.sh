#!/usr/bin/sh

#   Simple use of curl to test CA Player Direct player/self API's
#   Pete Jansz, 2018-09-06

SCRIPT=$(basename $0)

if [[ $# -lt 3 ]]; then
    echo "USAGE: $SCRIPT <hostname> <username> <password> [-quiet]"
    exit 1
fi

HOSTNAME=$1
USERNAME=$2
PASSWORD=$3
QUIET=$4

EX_SYS_ID=8
CHANNEL_ID=2
SITE_ID=35

PROTO='http'
if [[ "$HOSTNAME" =~ '.com' ]]; then
    PROTO="https"
fi

if [[ "$HOSTNAME" =~ "mobile" ]]; then
    CHANNEL_ID=3
fi

get()
{
    FUNCTION=$1
    curl -sX GET "${PROTO}://$HOSTNAME/api/v1/players/self/${FUNCTION}" \
      -H "x-ex-system-id: ${EX_SYS_ID}"     \
      -H "X-CHANNEL-ID: ${CHANNEL_ID}"      \
      -H "x-site-id: ${SITE_ID}"            \
      -H "authorization: OAuth ${OAUTH}"    \
      -H 'cache-control: no-cache'          \
      -H "x-device-uuid: ${SCRIPT}"
}

OAUTH=$(node ~pjansz/Documents/bin/pd-login.js -h $HOSTNAME -u $USERNAME -p $PASSWORD)

for fun in 'attributes' 'personal-info' 'profile' 'notifications-preferences' 'notifications' 'communication-preferences'; do
    CONTENT=$(get $fun)
    if [ $? != 0 ]; then
        echo "Failed: $fun \n$CONTENT"
        exit 1
    fi

    if [[ -z "$QUIET" ]]; then
        echo "Passed: $fun"
    fi
done