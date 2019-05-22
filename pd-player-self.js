/*
    Axios REST calls to PD player/self APIs, synchronous or async
    Pete Jansz
*/

const axios = require( 'axios' )
var program = require( 'commander' )
var igtCas = require( 'pete-lib/igt-cas' )
var path = require( 'path' )
const API_BASE_PATH = '/api/v1/players/self/'
const ALL_API_NAMES = ['attributes', 'communication-preferences', 'notifications', 'notifications-preferences', 'personal-info', 'profile']

program
    .version( '0.0.1' )
    .description( 'REST calls to PD player/self APIs' )
    .usage( '-h <host> -u <username> -p <password>' )
    .option( '-a, --async', 'Asynchronous mode' )
    .option( '-c, --count [count]', 'Repeat count times' )
    .option( '-h, --hostname <hostname>', 'Hostname' )
    .option( '-o, --oauth [oauth]', 'OAuth token' )
    .option( '-u, --username <username>', 'Username' )
    .option( '-p, --password <password>', 'Password' )
    .option( '--api <name,...>', 'Names: ' + ALL_API_NAMES, commanderList )
    .option( '-q, --quiet', 'Shhhh' )
    .parse( process.argv )

process.exitCode = 1

if ( !program.hostname )
{
    program.help()
}

if ( !program.username && !program.password && !program.oauth )
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
        var qualifiedHostname = program.hostname
        if ( qualifiedHostname.match( /cadev1$/i ) )
        {
            qualifiedHostname += '.gtech.com'
        }

        var loginRequest = igtCas.createLoginRequest( qualifiedHostname, program.username, program.password )
        axiosInstance = createAxiosInstance( qualifiedHostname )
        var oauthToken

        if ( !program.oauth )
        {
            // Login for the authCode:
            var promisedLoginAuthCodeResponse = await axiosInstance.post( '/api/v1/oauth/login', loginRequest )
            var authCode = promisedLoginAuthCodeResponse.data[0].authCode
            var oAuthTokensRequest = createOAuthTokensRequest( authCode, loginRequest )

            // Submit authCode for the oauthToken:
            var promisedTokenResponse = await axiosInstance.post( '/api/v1/oauth/self/tokens', oAuthTokensRequest )
            var mobileToken = promisedTokenResponse.data[0].token
            var pwsToken = promisedTokenResponse.data[1].token
            oauthToken = qualifiedHostname.match( /mobile/ ) ? mobileToken : pwsToken
        }
        else
        {
            oauthToken = program.oauth
        }

        axiosInstance.defaults.headers.common['Authorization'] = "OAuth " + oauthToken
        var objects = {}
        var count = program.count ? program.count : 1
        while ( count > 0 )
        {
            count--
            if ( !program.async )
            {
                for ( var index in apiNames )
                {
                    var name = apiNames[index]
                    var promise = await axiosInstance.get( API_BASE_PATH + name )
                    objects[name] = promise.data
                }

                if ( !program.quiet )
                {
                    console.log( JSON.stringify( objects ) )
                }
            }
            else
            {
                var promises = []
                for ( var index in apiNames )
                {
                    var name = apiNames[index]
                    promises.push( axiosInstance.get( API_BASE_PATH + name ) )
                }

                Promise.all( promises )
                    .then( function ( values )
                    {
                        for ( var i = 0; i < values.length; i++ )
                        {
                            var url = values[i].config.url
                            var name = path.basename( url )
                            var data = values[i].data
                            objects[name] = data
                        }

                        if ( !program.quiet )
                        {
                            console.log( JSON.stringify( objects ) )
                        }
                    } )
            }
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
