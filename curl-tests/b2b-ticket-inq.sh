#! /bin/sh

#
# Pete's ESA B2B ticket inquiry
#

proto=http
gametype=''
DEFAULT_PORT=8680
port=$DEFAULT_PORT
ticket=''
CA_SITE_ID=35
CA_ORIG_ID='10002,0,0,0'
CA_REQ_ID=0
help=false
origid=$CA_ORIG_ID
reqid=$CA_REQ_ID
siteid=$CA_SITE_ID

help()
{
  echo "USAGE: $(basename $0) [options] --host <host> -g <draw|instant> -t <ticket>"
  echo "  options"
  echo "       --https (default=http)"
  echo "       --host <host>"
  echo "  -p | --port num (default=${DEFAULT_PORT})"
  echo "  -g | --gametype <draw | instant>"
  echo "       --origid   <origid (default=${CA_ORIG_ID})>"
  echo "       --reqid    <reqid  (default=${CA_REQ_ID})>"
  echo "       --siteid   <siteid (default=${CA_SITE_ID})>"
  echo "  -t | --ticket   <ticket>"
  echo "  -h | --help"
}

# options parser:
OPTS=$(getopt -o hp:g:t: --long https,host:,port:,gametype:,ticket:,help,origid:,reqid:,siteid: -n 'parse-options' -- "$@")
if [ $? != 0 ]; then
  echo "Failed parsing options." >&2
  exit 1
fi

eval set -- "$OPTS"

while true; do
  case "$1" in
           --https     ) proto=https;     shift ;;
           --host     ) host="$2";     shift; shift ;;
      -p | --port     ) port="$2";     shift; shift ;;
      -g | --gametype ) gametype="$2"; shift; shift ;;
           --origid   ) origid="$2";   shift; shift ;;
           --reqid    ) reqid="$2";    shift; shift ;;
           --siteid   ) siteid="$2";   shift; shift ;;
      -t | --ticket   ) ticket="$2";   shift; shift ;;
      -h | --help     ) help=true;     shift ;;
      -- ) shift; break ;;
      * ) break ;;
  esac
done

if [[ "$help" == 'true' || -z "$host" || -z "$ticket" ]]; then
  help
  exit 1
fi

if [ "$gametype" = "draw" ]; then
  propname=ticketSerialNumber
else
  gametype=instant
  propname=barcode
fi

if [[ "$proto" = "http" ]]; then
  URI="http://${host}:${port}/api/v2/${gametype}-games/tickets/inquire"
else
  URI="https://${host}/api/v2/${gametype}-games/tickets/inquire"
fi

curl -sX POST $URI                          \
  -H 'Cache-Control: no-cache'             \
  -H 'content-type: application/json'      \
  -H "x-originator-id: ${origid}"      \
  -H "x-request-id: ${reqid}"          \
  -H "x-site-id: ${siteid}"            \
  -d "{ \"${propname}\" : \"${ticket}\" }"

echo
