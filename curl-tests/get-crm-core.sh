#! /bin/sh

#   Make GET calls to CA PD crm-core california-adapter/player/self API's
#     VALID_CRM_ADAPTER_API_NAMES=(communication-preferences notifications notifications-preferences personal-info profile)
#   Pete Jansz, IGT, 2020-04-15

EXECUTING_DIR=$( dirname $(readlink -f $0 ))
. $EXECUTING_DIR/pd-ca-lib.sh

SCRIPT=$(basename $0)
HOST=
# Defaults:
QUIET=false
HELP=false
VERBOSE=false
WAIT=0    # seconds
DEFAULT_CURL_OPTS="-o /dev/null -s -w %{http_code}"
let COUNT=1

VALID_CRM_ADAPTER_API_NAMES=(communication-preferences notifications notifications-preferences personal-info profile)
OAUTH=MyOAuthSessionToken123
PLAYER_ATTRIBUTES='1=2;500=2'
function help()
{
  local api_names=''

  for name in ${VALID_CRM_ADAPTER_API_NAMES[*]}; do
    api_names="${api_names} ${name}"
  done

  echo "Make GET calls to CA PD crm-core california-adapter/player/self API's"                    >&2
  echo "  $api_names"                                                                             >&2
  echo                                                                                            >&2
  echo "USAGE: $(basename $0) [options] -h <crm-core-host> -p <player-id> --api <api-name>"       >&2
  echo "  options"                                                                                >&2
  echo "  -h | --host     <host>"                                                                 >&2
  echo "  -c | --count    <number (default=1)> Repeat API calls"                                  >&2
  echo "  -w | --wait     <seconds (default=0)> If count specified, option to wait between calls" >&2
  echo "  -p | --playerid <player-id>"                                                            >&2
  echo '  -q | --quiet'                                                                           >&2
  echo "  -v | --verbose"                                                                         >&2
  echo '  -?   --help'                                                                            >&2
}

# options parser:
OPTS=$(getopt -o c:h:w:p:qv --long api:,count:,wait:,host:,playerid:,help,quiet,verbose -n 'parse-options' -- "$@")
if [ $? != 0 ]; then
  help
  exit 1
fi
eval set -- "$OPTS"

while true; do
  case "$1" in
      -h | --host     ) HOST="$2";      shift; shift ;;
      -c | --count    ) COUNT="$2";     shift; shift ;;
      -p | --playerid ) PLAYER_ID="$2";  shift; shift ;;
      -w | --wait     ) WAIT="$2";      shift; shift ;;
           --api      ) API_NAME="$2";  shift; shift ;;
      -q | --quiet    ) QUIET=true;     shift ;;
      -v | --verbose  ) VERBOSE=true;   shift ;;
           --help     ) HELP=true;      shift ;;
      -- )                              shift; break ;;
       * )                              break ;;
  esac
done

if [[ "$HELP" == 'true' || -z "$HOST" || -z "$API_NAME" || -z "$PLAYER_ID" ]]; then
  help
  exit 1
fi

VALIDATED=false
for valid_name in ${VALID_CRM_ADAPTER_API_NAMES[*]}; do
  if [[ $API_NAME == $valid_name ]]; then
    VALIDATED=true
  fi
done

if [[ "$VALIDATED" == 'false' ]]; then
  help
  exit 1
fi

function get_ca_adapter_api()
{
  local CURL_OPTS='-isX'

  if [[ $VERBOSE == 'true' ]]; then
      CURL_OPTS="-v ${CURL_OPTS}"
  fi

  RESP=$( curl $CURL_OPTS GET "http://${HOST}:8280/california-adapter/api/v1/players/self/${API_NAME}" \
  -H 'cache-control: no-cache'                                                                     \
  -H 'content-type: application/json'                                                              \
  -H 'connection: keep-alive'                                                                      \
  -H "authorization: OAuth ${OAUTH}"                                                               \
  -H "x-ex-system-id: ${CA_SYSTEM_ID}"                                                             \
  -H "x-channel-id: ${CA_PWS_CHANNEL_ID}"                                                          \
  -H "x-player-id: ${PLAYER_ID}"                                                                   \
  -H "x-player-attributes: ${PLAYER_ATTRIBUTES}" )

  echo $RESP
}

EXIT_CODE=1

while [[ $COUNT -ne 0 ]]; do
  RESPONSE=$( get_ca_adapter_api )
  STATUS_CODE=$( echo "${RESPONSE}" | awk '/^HTTP/{print $2}')

  BODY=''
  # Find body in response:
  for line in $RESPONSE; do
    if [[ $line =~ '{' ]] || [[ $line =~ '}' ]]; then
      S=$( echo $line | sed 's/^ //g' )
      BODY="${BODY}${S}"
    fi
  done

  if  [[ $STATUS_CODE == '200' ]]; then
    EXIT_CODE=0
  else
    EXIT_CODE=1
  fi

  if [[ $QUIET == 'false' ]]; then
    echo "$STATUS_CODE/${BODY}"
  fi

  if [[ $EXIT_CODE == 1 ]]; then
    break
  fi

  let COUNT--
  sleep $WAIT
done

exit $EXIT_CODE
