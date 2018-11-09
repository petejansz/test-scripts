#!/usr/bin/sh

#   Sh test CA Player Direct player/self API's
#   Login, get oauth token, make GET calls:
#     'attributes' 'personal-info' 'profile' 'notifications-preferences' 'communication-preferences
#   Pete Jansz, 2018-11-10

SCRIPT=$(basename $0)
HOST=
USERNAME=
PASSWORD=
CA_SITE_ID=35
CA_MOBILE_CLIENT_ID=CAMOBILEAPP
CA_PWS_CLIENT_ID=SolSet2ndChancePortal
CA_MOBILE_CHANNEL_ID=3
CA_PWS_CHANNEL_ID=2
CA_SYSTEM_ID=8

# Defaults:
QUIET=false
HELP=false
siteId=$CA_SITE_ID
channelId=$CA_PWS_CHANNEL_ID
clientId=$CA_PWS_CLIENT_ID
esaApiKey=DBRDtq3tUERv79ehrheOUiGIrnqxTole
let COUNT=1

function help()
{
  echo "Test CA Player Direct player/self API's"                                   >&2
  echo "Login, get oauth token, make GET calls to:"                                >&2
  echo "  attributes, personal-info, profile, notifications-preferences, communication-preferences" >&2
  echo                                                                             >&2
  echo "USAGE: $(basename $0) [options] -h <hostname> -u <username> -p <password>" >&2
  echo "  options"                                                                 >&2
  echo "  -h | --host     <host>"                                                  >&2
  echo "  -c | --count    <number (default=1)> Repeat API calls               "    >&2
  echo "  -u | --username <username>"                                              >&2
  echo "  -p | --password <password>"                                              >&2
  echo '  -q | --quiet'                                                            >&2
  echo '  -?   --help'                                                             >&2
}

# options parser:
OPTS=$(getopt -o c:h:u:p:q --long count:,host:,username:,password:,help,siteid:,quiet -n 'parse-options' -- "$@")
if [ $? != 0 ]; then
  help
  exit 1
fi
eval set -- "$OPTS"

while true; do
  case "$1" in
      -h | --host     ) HOST="$2";     shift; shift ;;
      -c | --count    ) COUNT="$2";    shift; shift ;;
      -p | --password ) PASSWORD="$2"; shift; shift ;;
      -u | --username ) USERNAME="$2"; shift; shift ;;
      -q | --quiet    ) QUIET=true;    shift ;;
           --help     ) HELP=true;     shift ;;
      -- )                             shift; break ;;
       * )                             break ;;
  esac
done

if [[ "$HELP" == 'true' || -z "$HOST" || -z "$USERNAME" || -z "$PASSWORD" ]]; then
  help
  exit 1
fi

HOSTNAME=$HOST
PROTO=http
if [[ "$HOSTNAME" =~ '.com' ]]; then
    PROTO=https
fi

if [[ $HOST =~ "mobile" ]]; then
    channelId=$CA_MOBILE_CHANNEL_ID
    clientId=$CA_MOBILE_CLIENT_ID
fi

function get_players_self() # input-params: FUNCTION_NAME; output-value: JSON_CONTENT
{
    local FUNCTION_NAME=$1
    local CURL_OPTS=$2
    if [[ -z "$CURL_OPTS" ]]; then
      local CURL_OPTS="-o -I -L -s -w %{http_code}"
    fi

    curl $CURL_OPTS "${PROTO}://$HOSTNAME/api/v1/players/self/${FUNCTION_NAME}" \
      -H 'cache-control: no-cache'                      \
      -H 'content-type: application/json'               \
      -H "x-site-id: $siteId"                           \
      -H "x-ex-system-id: $CA_SYSTEM_ID"                \
      -H "x-channel-id: $channelId"                     \
      -H "x-esa-api-key: ${esaApiKey}"                  \
      -H "x-clientip: $(hostname)"                      \
      -H "authorization: OAuth ${OAUTH}"                \
      -H "x-device-uuid: ${SCRIPT}"
}

function pd_login() # input-params: $HOSTNAME $USERNAME $PASSWORD; output-value: $OAUTH_TOKEN
{
    local HOSTNAME=$1
    local USERNAME=$2
    local PASSWORD=$3
    local OAUTH_TOKEN=$(oauth-login.sh -h $HOSTNAME -u $USERNAME -p $PASSWORD)
    echo "${OAUTH_TOKEN}"
}

function exec_players_self_apis()
{
    for fun in 'attributes' 'personal-info' 'profile' 'notifications-preferences' 'communication-preferences'; do
        RESPONSE_CODE=$(get_players_self $fun)

        if [[ $RESPONSE_CODE != 200 ]]; then
            echo "Failed: $fun : $RESPONSE_CODE"
            exit 1
        fi

        if [[ "$QUIET" =~ 'false'  ]]; then
            echo "Response code ${RESPONSE_CODE}: $fun"
        fi
    done
}

#echo "Is email available? $(is_email_available $USERNAME)"
OAUTH=$(pd_login $HOSTNAME $USERNAME $PASSWORD)
while [[ $COUNT -ne 0 ]]; do
  exec_players_self_apis
  let COUNT--
done
