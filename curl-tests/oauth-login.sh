#! /bin/sh

#   OAuth login to CA Player Direct, write oauth-token to stdout
#   Pete Jansz, IGT, 2018-11-10

. pd-ca-lib.sh

SCRIPT=$(basename $0)
HOST=
PORT=
USERNAME=
PASSWORD=

# Defaults:
QUIET=false
HELP=false
PWS_TOKEN_CUT_FLD_NR=16
MOB_TOKEN_CUT_FLD_NR=6
TOKEN_CUT_FIELD_NR=$PWS_TOKEN_CUT_FLD_NR

function help()
{
  echo "OAuth login to CA Player Direct, write oauth-token to stdout"              >&2
  echo "    port default=sec-gateway port ${SEC_GW_PORT} when host =~ IP-address"  >&2
  echo ""                                                                          >&2
  echo "USAGE: $SCRIPT [options] -h <host> -u <username> -p <password>"            >&2
  echo "  options"                                                                 >&2
  echo "       --port     <port>"                                                  >&2
  echo '  -?   --help'                                                             >&2
}

# options parser:
OPTS=$(getopt -o h:u:p: --long host:,username:,password:,port:,help -n 'parse-options' -- "$@")
if [ $? != 0 ]; then
  help
  exit 1
fi
eval set -- "$OPTS"

while true; do
  case "$1" in
      -h | --host     ) HOST="$2";     shift; shift ;;
           --port     ) PORT="$2";     shift; shift ;;
      -p | --password ) PASSWORD="$2"; shift; shift ;;
      -u | --username ) USERNAME="$2"; shift; shift ;;
           --help     ) HELP=true;     shift ;;
      -- )                             shift; break ;;
       * )                             break ;;
  esac
done

if [[ "$HELP" == 'true' || -z "$HOST" || -z "$USERNAME" || -z "$PASSWORD" ]]; then
  help
  exit 1
fi

if [[ $HOST =~ "mobile" ]]; then
    channelId=$CA_MOBILE_CHANNEL_ID
    clientId=$CA_MOBILE_CLIENT_ID
    TOKEN_CUT_FIELD_NR=$MOB_TOKEN_CUT_FLD_NR
fi

BASE_URI=$(create_base_uri $HOST $PORT)
RESOURCE_CREDS="\"resourceOwnerCredentials\": {\"USERNAME\":\"${USERNAME}\", \"PASSWORD\":\"${PASSWORD}\"}"

RESP=$(curl -ksX POST \
  "${BASE_URI}/api/v1/oauth/login"       \
  -H 'cache-control: no-cache'                      \
  -H 'content-type: application/json'               \
  -H "x-site-id: $siteId"                           \
  -H "x-ex-system-id: $CA_SYSTEM_ID"                \
  -H "x-channel-id: $channelId"                     \
  -H "x-esa-api-key: ${esaApiKey}"                  \
  -H "x-clientip: $(hostname)"                      \
  -d "{ \"siteId\":\"${siteId}\", \"clientId\":\"${clientId}\", ${RESOURCE_CREDS} }")

if [[ $? > 0 ]]; then
    echo "oauth/login failed" >&2
    echo "${RESP}"            >&2
    exit 1
fi

AUTH_CODE=$(echo ${RESP} | cut -d: -f 6 | cut -d, -f 1 | sed 's/"//g')

if [[ -z "${AUTH_CODE}" ]]; then
    echo "oauth/login failed, can't parse for authCode" >&2
    exit 1
fi

TOKENS_RESP=$(curl -ksX POST \
  "${BASE_URI}/api/v1/oauth/self/tokens" \
  -H 'cache-control: no-cache'                      \
  -H 'content-type: application/json'               \
  -H "x-site-id: $siteId"                           \
  -H "x-ex-system-id: $CA_SYSTEM_ID"                \
  -H "x-channel-id: $channelId"                     \
  -H "x-esa-api-key: ${esaApiKey}"                  \
  -H "x-clientip: $(hostname)"                      \
  -d "{ \"authCode\" : \"${AUTH_CODE}\",  \"siteId\":\"${siteId}\", \"clientId\":\"${clientId}\" }" )

MOB_TOKEN=$(echo $TOKENS_RESP | cut -d, -f $MOB_TOKEN_CUT_FLD_NR | sed 's/"//g'| cut -d: -f2)
PWS_TOKEN=$(echo $TOKENS_RESP | cut -d, -f $PWS_TOKEN_CUT_FLD_NR | sed 's/"//g'| cut -d: -f2)
if [[ $TOKEN_CUT_FIELD_NR = $MOB_TOKEN_CUT_FLD_NR ]]; then
    echo $MOB_TOKEN
else
    echo $PWS_TOKEN
fi