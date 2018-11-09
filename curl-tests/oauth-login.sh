#!/usr/bin/sh

#   OAuth login to CA Player Direct, write oauth-token to stdout
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
PWS_TOKEN_CUT_FLD_NR=16
MOB_TOKEN_CUT_FLD_NR=6
TOKEN_CUT_FIELD_NR=$PWS_TOKEN_CUT_FLD_NR

function help()
{
  echo "OAuth login to CA Player Direct, write oauth-token to stdout"              >&2
  echo ""                                                                          >&2
  echo "USAGE: $SCRIPT [options] -h <hostname> -u <username> -p <password>"        >&2
  echo "  options"                                                                 >&2
  echo "  -h | --host     <host>"                                                  >&2
  echo "  -u | --username <username>"                                              >&2
  echo "  -p | --password <password>"                                              >&2
  echo '  -?   --help'                                                             >&2
}

# options parser:
OPTS=$(getopt -o h:u:p: --long host:,username:,password:,help -n 'parse-options' -- "$@")
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

HOSTNAME=$HOST
PROTO=http
if [[ "$HOSTNAME" =~ '.com' ]]; then
    PROTO=https
fi

RESOURCE_CREDS="\"resourceOwnerCredentials\": {\"USERNAME\":\"${USERNAME}\", \"PASSWORD\":\"${PASSWORD}\"}"

AUTH_CODE=$(curl -sX POST \
  "${PROTO}://${HOSTNAME}/api/v1/oauth/login"       \
  -H 'cache-control: no-cache'                      \
  -H 'content-type: application/json'               \
  -H "x-site-id: $siteId"                           \
  -H "x-ex-system-id: $CA_SYSTEM_ID"                \
  -H "x-channel-id: $channelId"                     \
  -H "x-esa-api-key: ${esaApiKey}"                  \
  -H "x-clientip: $(hostname)"                      \
  -d "{ \"siteId\":\"${siteId}\", \"clientId\":\"${clientId}\", ${RESOURCE_CREDS} }" \
  | cut -d: -f 6 | cut -d, -f 1 | sed 's/"//g')

TOKENS_RESP=$(curl -sX POST \
  "${PROTO}://${HOSTNAME}/api/v1/oauth/self/tokens" \
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
