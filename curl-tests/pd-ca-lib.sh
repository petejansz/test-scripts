# PD Lib of CA functions, constants
# Pete Jansz, IGT, 2018
#

CA_SITE_ID=35
CA_MOBILE_CLIENT_ID=CAMOBILEAPP
CA_PWS_CLIENT_ID=SolSet2ndChancePortal
CA_MOBILE_CHANNEL_ID=3
CA_PWS_CHANNEL_ID=2
CA_SYSTEM_ID=8
SEC_GW_PORT=8280
siteId=$CA_SITE_ID
channelId=$CA_PWS_CHANNEL_ID
clientId=$CA_PWS_CLIENT_ID
DEFAULT_ESA_API_KEY=di9bJ9MPTXOZvEKAvd7CM8cRJ4Afo54b

function qualified_cadev_name # ("cadev1|cadev1.gtech.com") : cadev1.gtech.com
{
    local HOST=$1
    local QUALIFIED_NAME="${HOST}"

    if [[ ! "${HOST}" =~ 'gtech.com' ]]; then
        QUALIFIED_NAME="${HOST}.gtech.com"
    fi

    echo "$QUALIFIED_NAME"
}

function create_base_uri
{
    local HOST=$1
    local PORT=$2

    if [[ "${HOST}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ && -z "$PORT" ]]; then
        PORT=$SEC_GW_PORT
        BASE_URI="http://${HOST}:${PORT}/california-gateway"
    elif [[ "${HOST}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ && "$PORT" ]]; then
        BASE_URI="http://${HOST}:${PORT}/california-gateway"
    elif [[ "${HOST}" =~ "cadev" ]]; then
        BASE_URI="http://$(qualified_cadev_name ${HOST})"
    else
        BASE_URI="https://${HOST}"
    fi

    echo $BASE_URI
}