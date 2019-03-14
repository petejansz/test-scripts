#! /bin/sh

#
# Pete's ESA B2B ticket inquiry
#

proto=http
gametype=''
port=8680
ticket=''
CA_SITE_ID=35
retailer=10002
store=6
terminal=7
teller=8
CA_ORIG_ID=$(printf "%s,%s,%s,%s" $retailer $store $terminal $teller)
CA_REQ_ID=0
help=false
origid=$CA_ORIG_ID
reqid=$CA_REQ_ID
siteid=$CA_SITE_ID
qs=''
RESP_CODE_ONLY=false
VERBOSE=false

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
  echo "  -v | --verbose"
  echo "  -h | --help"
}

# options parser:
OPTS=$(getopt -o cho:r:s:p:q:g:t:v --long https,host:,port:,gametype:,ticket:,help,origid:,reqid:,siteid:,qs:,code,verbose -n 'parse-options' -- "$@")
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
      -v | --verbose  ) VERBOSE=true;         shift ;;
      -h | --help     ) help=true;            shift ;;
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
  V=v2
else
  gametype=instant
  propname=barcode
  V=v1
fi

if [[ "$proto" = "http" ]]; then
  URI="http://${host}:${port}/api/${V}/${gametype}-games/tickets/inquire${qs}"
else
  URI="https://${host}/api/${V}/${gametype}-games/tickets/inquire${qs}"
fi

if [[ $VERBOSE =~ 'true' ]]; then
  CURL_OPTS="-isvX"
else
  CURL_OPTS="-isX"
fi
RESPONSE=$(curl $CURL_OPTS POST $URI        \
  -H 'cache-control: no-cache'              \
  -H 'content-type: application/json'       \
  -H "x-device-uuid: abc123uuid"            \
  -H "x-originator-id: ${origid}"           \
  -H "x-request-id: ${reqid}"               \
  -H "x-site-id: ${siteid}"                 \
  -d "{ \"${propname}\" : \"${ticket}\" }")
EXIT_CODE=$?

STATUS_CODE=$(echo "${RESPONSE}" | awk '/^HTTP/{print $2}')
BODY=$(echo "${RESPONSE}" | awk '/^{.*}$/{print $0}')

if [[ $EXIT_CODE != 0 || $VERBOSE =~ 'true' ]]; then
  echo "${RESPONSE}"
elif [[ $EXIT_CODE == 0 && $VERBOSE =~ 'false' ]]; then
  echo "${STATUS_CODE}/${BODY}"
else
  echo "${RESPONSE}"
fi

exit $EXIT_CODE
