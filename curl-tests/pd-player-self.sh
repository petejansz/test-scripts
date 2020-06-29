#! /bin/sh

#   Sh test CA Player Direct player/self API's
#   Login, get oauth token, make GET calls:
#     'attributes' 'personal-info' 'profile' 'notifications-preferences' 'communication-preferences
#   Pete Jansz, IGT, 2018-11-10

EXECUTING_DIR=$( dirname $(readlink -f $(which $0 )))
. $EXECUTING_DIR/pd-ca-lib.sh

SCRIPT=$(basename $0)
HOST=
USERNAME=
PASSWORD=
OAUTH=
AVAILABLE=
FORGOTTEN_PASSWORD=

# Defaults:
QUIET=false
HELP=false
VERBOSE=false
WAIT=0    # seconds
DEFAULT_ESA_API_KEY=DBRDtq3tUERv79ehrheOUiGIrnqxTole
DEFAULT_CURL_OPTS="-o /dev/null -s -w %{http_code}"
let COUNT=1
ALL_API_NAMES='attributes communication-preferences notifications notifications-preferences personal-info profile'

function help()
{
  echo "Test CA Player Direct player/self API's"                                                  >&2
  echo "Login, get oauth token, make GET calls to API-names:"                                     >&2
  echo "  $ALL_API_NAMES"                                                                         >&2
  echo                                                                                            >&2
  echo "USAGE: $(basename $0) [options] -h <host> -u <username> -p <password> | -o <oauth token>" >&2
  echo "   | --available <username> | --forgot[_pwd] <username>"                                  >&2
  echo "  options"                                                                                >&2
  echo "  -h | --host     <host>  To talk directly to sec-gateway use IP-address as host"         >&2
  echo "       --port     <port>  When host is an IP-address, port is set to sec-gateway 8280"    >&2
  echo "  -c | --count    <number (default=1)> Repeat API calls"                                  >&2
  echo "       --available <username>"                                                            >&2
  echo "  -w | --wait     <seconds (default=0)> If count specified, option to wait between calls" >&2
  echo "  -o | --oauth <oauth token>"                                                             >&2
  echo "  -u | --username <username>"                                                             >&2
  echo "  -p | --password <password>"                                                             >&2
  echo "       --api <\"name ... \"> names (default=${ALL_API_NAMES})"                            >&2
  echo '  -q | --quiet'                                                                           >&2
  echo "  -v | --verbose"                                                                         >&2
  echo '  -?   --help'                                                                            >&2
  echo '  ENVIRONMENT:'                                                                           >&2
  echo "      ESA_API_KEY  default=${DEFAULT_ESA_API_KEY}"                                        >&2
}

# options parser:
OPTS=$(getopt -o c:h:w:o:u:p:qv --long apis:,count:,wait:,host:,oauth:,username:,password:,port:,available:,forgot_pwd:,help,siteid:,quiet,verbose -n 'parse-options' -- "$@")

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
           --available ) AVAILABLE="$2" shift; shift ;;
           --forgot_pwd ) FORGOTTEN_PASSWORD="$2" shift; shift ;;
      -o | --oauth    ) OAUTH="$2";     shift; shift ;;
      -p | --password ) PASSWORD="$2";  shift; shift ;;
      -u | --username ) USERNAME="$2";  shift; shift ;;
      -w | --wait     ) WAIT="$2";      shift; shift ;;
           --apis     ) API_NAMES="$2"; shift; shift ;;
      -q | --quiet    ) QUIET=true;     shift ;;
      -v | --verbose  ) VERBOSE=true;   shift ;;
           --help     ) HELP=true;      shift ;;
      -- )                              shift; break ;;
       * )                              break ;;
  esac
done

if [[ "$HELP" == 'true' || -z "$HOST" ]]; then
  help
  exit 1
fi

if [[ -z "$OAUTH" && -z "$USERNAME" && -z "$PASSWORD"  && -z "$AVAILABLE" && -z "$FORGOTTEN_PASSWORD" ]]; then
  help
  exit 1
fi

if [[ $HOST =~ "mobile" ]]; then
    channelId=$CA_MOBILE_CHANNEL_ID
    clientId=$CA_MOBILE_CLIENT_ID
fi

if [[ -z "$API_NAMES" && -z "$AVAILABLE" && -z "$FORGOTTEN_PASSWORD" ]]; then
    API_NAMES=$ALL_API_NAMES
fi

function is_available()
{
    local CURL_OPTS=$1

    if [[ -z "$CURL_OPTS" ]]; then
      local CURL_OPTS=$DEFAULT_CURL_OPTS
    fi

    if [[ $VERBOSE == 'true' ]]; then
        CURL_OPTS="-v ${CURL_OPTS}"
    fi

    BASE_URI=$(create_base_uri $HOST $PORT)
    RESP=$(curl -s "${BASE_URI}/api/v1/players/available/${AVAILABLE}" \
      -H "x-ex-system-id: $CA_SYSTEM_ID" \
      -H "x-channel-id: $channelId" )

    echo $RESP
}

function forgotten_password()
{
    local CURL_OPTS=$1

    if [[ -z "$CURL_OPTS" ]]; then
      local CURL_OPTS=$DEFAULT_CURL_OPTS
    fi

    if [[ $VERBOSE == 'true' ]]; then
        CURL_OPTS="-v ${CURL_OPTS}"
    fi

    BASE_URI=$(create_base_uri $HOST $PORT)
    RESP=$(curl $CURL_OPTS -X PUT "${BASE_URI}/api/v1/players/forgotten-password" \
      -H "x-ex-system-id: $CA_SYSTEM_ID"                \
      -H "x-channel-id: $channelId"                     \
      -H 'content-type: application/json'               \
      --data-raw "{\"emailAddress\" : \"${FORGOTTEN_PASSWORD}\"}" )

    echo $RESP
}

function get_players_self() # input-params: FUNCTION_NAME; output-value: JSON_CONTENT
{
    local FUNCTION_NAME=$1
    local CURL_OPTS=$2

    if [[ -z "$CURL_OPTS" ]]; then
      local CURL_OPTS=$DEFAULT_CURL_OPTS
    fi

    if [[ -z "$ESA_API_KEY" ]]; then
      local ESA_API_KEY=$DEFAULT_ESA_API_KEY
    fi

    if [[ $VERBOSE == 'true' ]]; then
        CURL_OPTS="-v ${CURL_OPTS}"
    fi

    BASE_URI=$(create_base_uri $HOST $PORT)

    RESP=$(curl $CURL_OPTS "${BASE_URI}/api/v1/players/self/${FUNCTION_NAME}" \
      -H 'cache-control: no-cache'                      \
      -H 'content-type: application/json'               \
      -H "x-site-id: $siteId"                           \
      -H "x-ex-system-id: $CA_SYSTEM_ID"                \
      -H "x-channel-id: $channelId"                     \
      -H "x-esa-api-key: ${ESA_API_KEY}"                \
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
    if [[ $VERBOSE == 'true' ]]; then
      local OAUTH_TOKEN=$( $EXECUTING_DIR/oauth-login.sh -h $HOST -u $USERNAME -p $PASSWORD --verbose )
    else
      local OAUTH_TOKEN=$( $EXECUTING_DIR/oauth-login.sh -h $HOST -u $USERNAME -p $PASSWORD )
    fi

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

if [[ -z "$OAUTH" && -z "$AVAILABLE" && -z "$FORGOTTEN_PASSWORD" ]]; then
    OAUTH=$(pd_login $HOST $USERNAME $PASSWORD)
fi

while [[ $COUNT -ne 0 ]]; do
  if [[ -n "$OAUTH" ]]; then
    exec_players_self_apis
  fi

  if [[ -n "$AVAILABLE" ]]; then
    RESP=$( is_available )
    echo $RESP
  fi

  if [[ -n "$FORGOTTEN_PASSWORD" ]]; then
    RESP=$( forgotten_password )
    if [[ $RESP != 204 ]]; then
        echo "Failed: forgotten-password : $RESP"
        exit 1
    fi

    if [[ "$QUIET" =~ 'false'  ]]; then
        echo "Response code ${RESP}: forgotten-password"
    fi
  fi

  let COUNT--
  sleep $WAIT
done
