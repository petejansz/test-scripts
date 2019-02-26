/*
    Axios REST calls to PD player/self APIs, synchronous or async
    Pete Jansz
*/

const modulesPath = '/usr/share/node_modules/'
const axios = require( modulesPath + 'axios' )
var program = require( modulesPath + 'commander' )
var igtCas = require( modulesPath + 'pete-lib/igt-cas' )
const API_BASE_PATH = '/api/v1/players/self/'
const ALL_API_NAMES = ['attributes', 'communication-preferences', 'notifications', 'notifications-preferences', 'personal-info', 'profile']

program
    .version( '0.0.1' )
    .description( 'REST calls to PD player/self APIs' )
    .usage( '-h <host> -u <username> -p <password>' )
    .option( '-a, --async', 'Asynchronous mode' )
    .option( '-c, --count [count]', 'Repeat count times' )
    .option( '-h, --hostname <hostname>', 'Hostname' )
    .option( '-u, --username <username>', 'Username' )
    .option( '-p, --password <password>', 'Password' )
    .option( '--api <name,...>', 'Names: ' + ALL_API_NAMES, commanderList )
    .option( '-q, --quiet', 'Shhhh' )
    .parse( process.argv )

process.exitCode = 1

if ( !program.hostname && !program.username || !program.password )
{
    program.help()
}

var apiNames = []

if ( program.api )
{
    for ( var i = 0; i < program.api.length; i++ )
    {
        var name = program.api[i]
        if ( ALL_API_NAMES.indexOf( name ) > -1 )
        {
            apiNames.push( name )
        }
        else
        {
            program.help()
        }
    }
}
else
{
    apiNames = ALL_API_NAMES
}

var axiosInstance
main()

async function main()
{
    try
    {
        var loginRequest = igtCas.createLoginRequest( program.hostname, program.username, program.password )
        axiosInstance = createAxiosInstance( program.hostname )

        // Login for the authCode:
        var promisedLoginAuthCodeResponse = await axiosInstance.post( '/api/v1/oauth/login', loginRequest )
        var authCode = promisedLoginAuthCodeResponse.data[0].authCode
        var oAuthTokensRequest = createOAuthTokensRequest( authCode, loginRequest )

        // Submit authCode for the oauthToken:
        var promisedTokenResponse = await axiosInstance.post( '/api/v1/oauth/self/tokens', oAuthTokensRequest )
        var mobileToken = promisedTokenResponse.data[0].token
        var pwsToken = promisedTokenResponse.data[1].token
        var oauthToken = program.hostname.match( /mobile/ ) ? mobileToken : pwsToken

        axiosInstance.defaults.headers.common['Authorization'] = "OAuth " + oauthToken
        var output = {}

        if ( !program.async )
        {
            for ( var i = 0; i < apiNames.length; i++ )
            {
                var name = apiNames[i]
                var promise = await axiosInstance.get( API_BASE_PATH + apiNames[i] )
                output[name] = promise.data
            }

            console.log( JSON.stringify( output ) )
            process.exitCode = 0
            process.exit()
        }

        var count = program.count ? program.count : 1
        for ( var i = 0; i < count; i++ )
        {
            axios.all
                (
                    [
                        axiosInstance.get( API_BASE_PATH + 'attributes' ),
                        axiosInstance.get( API_BASE_PATH + 'communication-preferences' ),
                        axiosInstance.get( API_BASE_PATH + 'notifications' ),
                        axiosInstance.get( API_BASE_PATH + 'notifications-preferences' ),
                        axiosInstance.get( API_BASE_PATH + 'personal-info' ),
                        axiosInstance.get( API_BASE_PATH + 'profile' ),
                    ]
                )
                .then( axios.spread( function
                    (
                        promisedAttribs,
                        promisedCommPreferences,
                        promisedNotifications,
                        promisedNotifPreferences,
                        promisedProfile,
                        promisedPersInfo
                    )
                {
                    output['attributes'] = promisedAttribs.data
                    output['communication-preferences'] = promisedCommPreferences.data
                    output['notifications'] = promisedNotifications.data
                    output['notifications-preferences'] = promisedNotifPreferences.data
                    output['profile'] = promisedProfile.data
                    output['personal-info'] = promisedPersInfo.data

                    if ( !program.quiet ) { console.log( JSON.stringify( output ) ) }
                } )
                )
        }

        process.exitCode = 0
    }
    catch ( error )
    {
        axiosErrorHandler( error )
    }
}

function createAxiosInstance( host, oauthToken )
{
    var proto = 'https'

    if ( host.match( /dev/ ) )
    {
        proto = 'http'
    }

    var defaults =
    {
        baseURL: proto + '://' + host,
        headers: igtCas.createHeaders( host )
    }

    if ( oauthToken ) { defaults.headers['Authorization'] = 'OAuth ' + oauthToken }

    return axios.create( defaults )
}

function createOAuthTokensRequest( authCode, loginRequest )
{
    return oauthTokenRequest =
        {
            authCode: authCode,
            clientId: loginRequest.clientId,
            siteId: loginRequest.siteId
        }
}

function axiosErrorHandler( error )
{
    if ( error.response && error.response.status < 500 )
    {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx
        var response =
        {
            statusText: error.response.statusText,
            statusCode: error.response.status,
            data: error.response.data
        }

        console.error( response )
    }
    else if ( error.response && error.response.status >= 500 )
    {
        console.error( error.response.status )
        console.error( error.response.headers )
        console.error( error.response.data )
    }
    else if ( error.request )
    {
        // The request was made but no response was received
        // error.request is an instance of XMLHttpRequest in the browser and an instance of
        // http.ClientRequest in node.js
        console.error( error.request )
    }
    else
    {
        // Something happened in setting up the request that triggered an Error
        console.error( 'Error', error.message )
    }

    //console.error( error.config )
}

// values delimited by space or comma:
function commanderList( val )
{
    var tokens = []
    if ( val.match( / /g ) !== null )
    {
        tokens = val.split( ' ' )
    }
    else if ( val.match( /,/g ) !== null )
    {
        tokens = val.split( ',' )
    }
    else
    {
        tokens.push( val )
    }

    return tokens
}
