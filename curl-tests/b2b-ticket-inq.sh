#! /bin/sh

#
# Pete's ESA B2B ticket inquiry
#

proto=http
gametype=''
port=8680
ticket=''
CA_SITE_ID=35
CA_ORIG_ID='10002,0,0,0'
CA_REQ_ID=0
help=false
origid=$CA_ORIG_ID
reqid=$CA_REQ_ID
siteid=$CA_SITE_ID
qs=''

help()
{
  echo "ESA B2B ticket inquiry"
  echo "Ticket from stdin or -t ticket"
  echo "USAGE: $(basename $0) [options] --host <host> -g <draw|instant> [-t <ticket>]"
  echo "  options"
  echo "       --https (default=http)"
  echo "       --host <host>"
  echo "  -p | --port num (default=${port})"
  echo "  -g | --gametype <draw | instant>"
  echo "  -o | --origid   <origid (default=${CA_ORIG_ID})>"
  echo "  -r | --reqid    <reqid  (default=${CA_REQ_ID})>"
  echo "  -s | --siteid   <siteid (default=${CA_SITE_ID})>"
  echo "  -q | --qs       <query-string>, e.g., '?foo=bah&goo=guh'"
  echo "  -t | --ticket   <ticket>"
  echo "  -h | --help"
}

# options parser:
OPTS=$(getopt -o ho:r:s:p:q:g:t: --long https,host:,port:,gametype:,ticket:,help,origid:,reqid:,siteid:,qs: -n 'parse-options' -- "$@")
if [ $? != 0 ]; then
  echo "Failed parsing options." >&2
  exit 1
fi

eval set -- "$OPTS"

while true; do
  case "$1" in
           --https    ) proto=https;   shift ;;
           --host     ) host="$2";     shift; shift ;;
      -p | --port     ) port="$2";     shift; shift ;;
      -g | --gametype ) gametype="$2"; shift; shift ;;
      -o | --origid   ) origid="$2";   shift; shift ;;
      -r | --reqid    ) reqid="$2";    shift; shift ;;
      -s | --siteid   ) siteid="$2";   shift; shift ;;
      -q | --qs       ) qs="$2";       shift; shift ;;
      -t | --ticket   ) ticket="$2";   shift; shift ;;
      -h | --help     ) help=true;     shift ;;
      -- ) shift; break ;;
      * ) break ;;
  esac
done

if [[ "$help" == 'true' || -z "$host" ]]; then
  help
  exit 1
fi

if [[ -z "$ticket" ]]; then
  read ticket
fi


if [ "$gametype" = "draw" ]; then
  propname=ticketSerialNumber
else
  gametype=instant
  propname=barcode
fi

if [[ "$proto" = "http" ]]; then
  URI="http://${host}:${port}/api/v2/${gametype}-games/tickets/inquire${qs}"
else
  URI="https://${host}/api/v2/${gametype}-games/tickets/inquire${qs}"
fi

curl -sX POST $URI                          \
  -H 'Cache-Control: no-cache'              \
  -H 'content-type: application/json'       \
  -H "x-originator-id: ${origid}"           \
  -H "x-request-id: ${reqid}"               \
  -H "x-site-id: ${siteid}"                 \
  -d "{ \"${propname}\" : \"${ticket}\" }"

echo
