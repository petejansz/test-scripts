#!/usr/bin/sh

#   Simple use of curl to test CA Player Direct player/self API's
#   Pete Jansz, 2018-09-06

SCRIPT=$(basename $0)
EX_SYS_ID=8
# PWS
CHANNEL_ID=2
# CA
CA_SITE_ID=35

HOST=
PASSWORD=''
USERNAME=''
SITE_ID=$CA_SITE_ID
QUIET=false
HELP=false

function help()
{
  echo "USAGE: $(basename $0) [options] -h <hostname> -u <username> -p <password>" >&2
  echo "  options"                                                                 >&2
  echo "  -h | --host <host>"                                                      >&2
  echo "  -u | --username <username>"                                              >&2
  echo "  -p | --password <password>"                                              >&2
  echo "       --siteid   <siteid (default=${CA_SITE_ID})>"                        >&2
  echo '  -q | --quiet'                                                            >&2
  echo '  -?   --help'                                                             >&2
}

# options parser:
OPTS=$(getopt -o h:u:p:q --long host:,username:,password:,help,siteid:,quiet -n 'parse-options' -- "$@")
if [ $? != 0 ]; then
  help
  exit 1
fi
eval set -- "$OPTS"

while true; do
  case "$1" in
      -h | --host     ) HOST="$2";     shift; shift ;;
      -p | --password ) PASSWORD="$2"; shift; shift ;;
      -u | --username ) USERNAME="$2"; shift; shift ;;
           --siteid   ) SITE_ID="$2";  shift; shift ;;
      -q | --quiet    ) QUIET=true;    shift ;;
           --help     ) HELP=true;     shift ;;
      -- )                             shift; break ;;
      * )                              break ;;
  esac
done

if [[ "$HELP" == 'true' || -z "$HOST" || -z "$USERNAME" || -z "$PASSWORD" ]]; then
  help
  exit 1
fi

HOSTNAME=$HOST
PROTO='http'
if [[ "$HOSTNAME" =~ '.com' ]]; then
    PROTO="https"
fi

if [[ "$HOSTNAME" =~ "mobile" ]]; then
    CHANNEL_ID=3
fi

function is_email_available() # input-params: EMAIL_NAME; output-value: 'true' | 'false'
{
    local EMAIL_NAME=$1
    local AVAILABLE=$(curl -sX GET "${PROTO}://$HOSTNAME/api/v1/players/available/${EMAIL_NAME}"  \
      -H 'Cache-Control: no-cache'          \
      -H "x-ex-system-id: ${EX_SYS_ID}"     \
      -H "x-channel-id: ${CHANNEL_ID}")
    echo $AVAILABLE
}

function get_players_self() # input-params: FUNCTION_NAME; output-value: JSON_CONTENT
{
    local FUNCTION_NAME=$1
    local CURL_OPTS=$2
    if [[ -z "$CURL_OPTS" ]]; then
      local CURL_OPTS='-o -I -L -s -w %{http_code}'
    fi

    curl $CURL_OPTS "${PROTO}://$HOSTNAME/api/v1/players/self/${FUNCTION_NAME}" \
      -H "x-ex-system-id: ${EX_SYS_ID}"     \
      -H "x-channel-id: ${CHANNEL_ID}"      \
      -H "x-site-id: ${SITE_ID}"            \
      -H "authorization: OAuth ${OAUTH}"    \
      -H 'cache-control: no-cache'          \
      -H "x-device-uuid: ${SCRIPT}"
}

function pd_login() # input-params: $HOSTNAME $USERNAME $PASSWORD; output-value: $OAUTH_TOKEN
{
    local HOSTNAME=$1
    local USERNAME=$2
    local PASSWORD=$3
    local OAUTH_TOKEN=$(node ~pjansz/Documents/bin/pd-login.js -h $HOSTNAME -u $USERNAME -p $PASSWORD)
    echo "${OAUTH_TOKEN}"
}

function exec_players_self_apis()
{
    for fun in 'attributes' 'personal-info' 'profile' 'notifications-preferences' 'notifications' 'communication-preferences'; do
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

echo "Is email available? $(is_email_available $USERNAME)"
OAUTH=$(pd_login $HOSTNAME $USERNAME $PASSWORD)
exec_players_self_apis