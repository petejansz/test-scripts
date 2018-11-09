/*
    Axios aysynchronous/concurrent REST calls, wait for all responses, promises
    Pete Jansz
*/

const modulesPath = '/usr/share/node_modules/'
const axios = require( modulesPath + 'axios' )
var program = require( modulesPath + 'commander' )
var igtCas = require( modulesPath + 'pete-lib/igt-cas' )

program
    .version( '0.0.1' )
    .description( 'Axios aysynchronous/concurrent REST calls to PD player/self APIs' )
    .usage(  '-h <host> -u <username> -p <password>' )
    .option( '-c, --count [count]', 'Repeat count times' )
    .option( '-h, --hostname <hostname>', 'Hostname' )
    .option( '-u, --username [username]', 'Username' )
    .option( '-p, --password [password]', 'Password' )
    .option( '-q, --quiet', 'Shhhh' )
    .parse( process.argv )

process.exitCode = 1

if ( !program.hostname && !program.username || !program.password )
{
    program.help()
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
        var oAuthTokensRequest = createOAuthTokensRequest(authCode, loginRequest)

        // Submit authCode for the oauthToken:
        var promisedTokenResponse = await axiosInstance.post( '/api/v1/oauth/self/tokens',  oAuthTokensRequest )
        var mobileToken = promisedTokenResponse.data[0].token
        var pwsToken = promisedTokenResponse.data[1].token
        var oauthToken = program.hostname.match( /mobile/ ) ? mobileToken : pwsToken

        axiosInstance.defaults.headers.common['Authorization'] = "OAuth " + oauthToken

        var output = {}
        var count = program.count ? program.count : 1
        for ( var i = 0; i < count; i++ )
        {
            axios.all
                (
                [
                    getAttributes(),
                    getCommunicationPreferences(),
                    getNotifications(),
                    getNotificationPreferences(),
                    getProfile(),
                    getPersonalInfo()
                ]
                )
                .then( axios.spread( function
                    (
                        attribs, commPreferences, notifications, notifPreferences, profile, persInfo
                    )
                {
                    output.attributes = attribs.data
                    output.communicationPreferences = commPreferences.data
                    output.notifications = notifications.data
                    output.notifPreferences = notifPreferences.data
                    output.profile = profile.data
                    output.personalInfo = persInfo.data

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

async function loggedInAxios( host, credentials )
{
    var reqData = igtCas.createLoginRequest( host )
    reqData.resourceOwnerCredentials = { USERNAME: credentials.username, PASSWORD: credentials.password }
    var axiosInstance = createAxiosInstance( host )

    // Get OAuth authCode
    axiosInstance.post( '/api/v1/oauth/login', reqData )
    var resultPromise = await oauthAxiosInstance.post( '/api/v1/oauth/login', oauthLoginRequest )
    var oauthTokenRequest =
    {
        authCode: resultPromise.data[0].authCode,
        clientId: clientId,
        siteId: siteId
    }

    return axiosInstance.post( '/api/v1/oauth/self/tokens', oauthTokenRequest )
}

function createOAuthTokensRequest(authCode, loginRequest)
{
    return oauthTokenRequest =
    {
        authCode: authCode,
        clientId: loginRequest.clientId,
        siteId: loginRequest.siteId
    }
}

function getAttributes()
{
    return axiosInstance.get( '/api/v1/players/self/attributes' )
}

function axiosErrorHandler( error )
{
    if ( error.response )
    {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx
        console.error( error.response.data )
        console.error( error.response.status )
        console.error( error.response.headers )
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
    console.error( error.config )
}

function getCommunicationPreferences()
{
    return axiosInstance.get( '/api/v1/players/self/communication-preferences' )
}

function getNotifications()
{
    return axiosInstance.get( '/api/v1/players/self/notifications' )
}

function getNotificationPreferences()
{
    return axiosInstance.get( '/api/v1/players/self/notifications-preferences' )
}

function getProfile()
{
    return axiosInstance.get( '/api/v1/players/self/profile' )
}

function getPersonalInfo()
{
    return axiosInstance.get( '/api/v1/players/self/personal-info' )
}

