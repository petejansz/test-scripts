#!/bin/sh

EXECUTING_DIR=$( dirname $(readlink -f $(which $0 )))
. $EXECUTING_DIR/pd-ca-lib.sh

SCRIPT=$(basename $0)
HOST=

# Defaults:
QUIET=false
HELP=false
VERBOSE=false
DEFAULT_CURL_OPTS="-o /dev/null -s -w %{http_code}"
PROTO=https
PROMO='false'
EVENT='false'
TOKEN=

function help()
{
  echo "Call player unsubscribe promo or event API"                                               >&2
  echo                                                                                            >&2
  echo "USAGE: $(basename $0) [options] -h <host> <-promo | -event> token "                    >&2
  echo "  options"                                                                                >&2
  echo "  -h | --host     <host>                                                        "         >&2
  echo "  --event         <token>"                                                                >&2
  echo "  --promo         <token>"                                                                >&2
  echo '  -q | --quiet'                                                                           >&2
  echo "  -v | --verbose"                                                                         >&2
  echo '  -?   --help'                                                                            >&2
}

# options parser:
SHORT_OPTS=h:qv
LONG_OPTS=host:,event:,promo:,help,quiet,verbose
OPTS=$(getopt -o $SHORT_OPTS --long $LONG_OPTS -n 'parse-options' -- "$@")

if [ $? != 0 ]; then
  help
  exit 1
fi
eval set -- "$OPTS"

while true; do
  case "$1" in
      -h | --host     ) HOST="$2";      shift; shift ;;
           --event ) EVENT='true'; TOKEN=$2; shift; shift ;;
           --promo ) PROMO='true'; TOKEN=$2; shift; shift ;;
      -q | --quiet    ) QUIET=true;     shift ;;
      -v | --verbose  ) VERBOSE=true;   shift ;;
           --help     ) HELP=true;      shift ;;
      -- )                              shift; break ;;
       * )                              break ;;
  esac
done

if [[ "$HELP" == 'true' || -z "$HOST" || -z "$TOKEN" ]]; then
  help
  exit 1
fi

if [[ ! "$HOST" =~ '.com' ]]; then
    PROTO=http
fi

function make_the_call
{
    if [[ $PROMO == 'true' ]]; then
        URL="${PROTO}://${HOST}/api/v1/players/notifications/promo/unsubscribe/${TOKEN}"
    else
        URL="${PROTO}://${HOST}/api/v1/notifications/unsubscribe?token=${TOKEN}"
    fi

    if [[ $VERBOSE == 'true' ]]; then
        echo $URL
    fi

    RESPONSE=$( curl $DEFAULT_CURL_OPTS -sX POST "${URL}" \
      -H 'content-type: application/json'     \
      -H "x-site-id: $siteId"                 \
      -H "x-ex-system-id: $CA_SYSTEM_ID"      \
      -H "x-channel-id: $channelId"           )

    echo $RESPONSE
}

RESP=$( make_the_call $TOKEN )
printf "%s\n" $RESP