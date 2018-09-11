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

help()
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

get()
{
    FUNCTION=$1

    PROTO='http'
    if [[ "$HOSTNAME" =~ '.com' ]]; then
        PROTO="https"
    fi

    if [[ "$HOSTNAME" =~ "mobile" ]]; then
        CHANNEL_ID=3
    fi

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

    if [[ "$QUIET" =~ 'false'  ]]; then
        echo "Passed: $fun"
    fi
done