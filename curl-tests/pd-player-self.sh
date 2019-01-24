#! /bin/sh

#   Sh test CA Player Direct player/self API's
#   Login, get oauth token, make GET calls:
#     'attributes' 'personal-info' 'profile' 'notifications-preferences' 'communication-preferences
#   Pete Jansz, IGT, 2018-11-10

. pd-ca-lib.sh

SCRIPT=$(basename $0)
HOST=
USERNAME=
PASSWORD=

# Defaults:
QUIET=false
HELP=false
let COUNT=1
ALL_API_NAMES='attributes personal-info profile notifications-preferences communication-preferences'

function help()
{
  echo "Test CA Player Direct player/self API's"                                   >&2
  echo "Login, get oauth token, make GET calls to API-names:"                      >&2
  echo "  $ALL_API_NAMES"                                                          >&2
  echo                                                                             >&2
  echo "USAGE: $(basename $0) [options] -h <host> -u <username> -p <password>"     >&2
  echo "  options"                                                                 >&2
  echo "  -h | --host     <host>"                                                  >&2
  echo "       --port     <port>"                                                  >&2
  echo "  -c | --count    <number (default=1)> Repeat API calls"                   >&2
  echo "  -u | --username <username>"                                              >&2
  echo "  -p | --password <password>"                                              >&2
  echo "       --apis <\"name ... \"> from API-names (default=all)"                >&2
  echo '  -q | --quiet'                                                            >&2
  echo '  -?   --help'                                                             >&2
}

# options parser:
OPTS=$(getopt -o c:h:u:p:q --long apis:,count:,host:,username:,password:,port:,help,siteid:,quiet -n 'parse-options' -- "$@")
if [ $? != 0 ]; then
  help
  exit 1
fi
eval set -- "$OPTS"

while true; do
  case "$1" in
      -h | --host     ) HOST="$2";      shift; shift ;;
           --port     ) PORT="$2";      shift; shift ;;
      -c | --count    ) COUNT="$2";     shift; shift ;;
      -p | --password ) PASSWORD="$2";  shift; shift ;;
      -u | --username ) USERNAME="$2";  shift; shift ;;
           --apis     ) API_NAMES="$2"; shift; shift ;;
      -q | --quiet    ) QUIET=true;     shift ;;
           --help     ) HELP=true;      shift ;;
      -- )                              shift; break ;;
       * )                              break ;;
  esac
done

if [[ "$HELP" == 'true' || -z "$HOST" || -z "$USERNAME" || -z "$PASSWORD" ]]; then
  help
  exit 1
fi

if [[ $HOST =~ "mobile" ]]; then
    channelId=$CA_MOBILE_CHANNEL_ID
    clientId=$CA_MOBILE_CLIENT_ID
fi

if [[ -z "$API_NAMES" ]]; then
    API_NAMES=$ALL_API_NAMES
fi

function get_players_self() # input-params: FUNCTION_NAME; output-value: JSON_CONTENT
{
    local FUNCTION_NAME=$1
    local CURL_OPTS=$2
    if [[ -z "$CURL_OPTS" ]]; then
      local CURL_OPTS="-o /dev/null -s -w %{http_code}"
    fi

    BASE_URI=$(create_base_uri $HOST $PORT)

    RESP=$(curl $CURL_OPTS "${BASE_URI}/api/v1/players/self/${FUNCTION_NAME}" \
      -H 'cache-control: no-cache'                      \
      -H 'content-type: application/json'               \
      -H "x-site-id: $siteId"                           \
      -H "x-ex-system-id: $CA_SYSTEM_ID"                \
      -H "x-channel-id: $channelId"                     \
      -H "x-esa-api-key: ${esaApiKey}"                  \
      -H "x-clientip: $(hostname)"                      \
      -H "authorization: OAuth ${OAUTH}"                \
      -H "x-device-uuid: ${SCRIPT}")

    echo $RESP
}

function pd_login() # input-params: $HOST $USERNAME $PASSWORD; output-value: $OAUTH_TOKEN
{
    local HOST=$1
    local USERNAME=$2
    local PASSWORD=$3
    local OAUTH_TOKEN=$(oauth-login.sh -h $HOST -u $USERNAME -p $PASSWORD)
    echo "${OAUTH_TOKEN}"
}

function exec_players_self_apis()
{
    for fun in $API_NAMES; do
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
OAUTH=$(pd_login $HOST $USERNAME $PASSWORD)
while [[ $COUNT -ne 0 ]]; do
  exec_players_self_apis
  let COUNT--
done
