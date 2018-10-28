/*
    Axios concurrent REST calls, wait for all responses, promises
*/

const modulesPath = '/usr/share/node_modules/'
const axios = require( modulesPath + 'axios' )
var program = require( modulesPath + 'commander' )

program
    .version( '0.0.1' )
    .description( 'NodeJS CLI to login, call some PD APIs' )
    .usage( '-h <host> -u <username> -p <password>' )
    .option( '-h, --hostname <hostname>', 'Hostname' )
    .option( '-t, --token <token>', 'OAuth token' )
    .parse( process.argv )

process.exitCode = 1

if ( !program.hostname && !program.token )
{
    program.help()
}

var host = program.hostname
var oauthToken = program.token
var axiosCadev1Players = createAxiosInstance( host, oauthToken )

function createAxiosInstance( host, oauthToken )
{
    var proto = host.match( /dev/i ) ? 'http' : 'https'

    return axios.create( {
        baseURL: proto + '://' + host + '/api/v1/players/self',
        headers: { 'X-EX-SYSTEM-ID': '8', 'X-CHANNEL-ID': '2', 'X-SITE-ID': '35', "Authorization": "OAuth " + oauthToken }
    } )
}

function getAttributes()
{
    return axiosCadev1Players.get( '/attributes' )
}

function getCommunicationPreferences()
{
    return axiosCadev1Players.get( '/communication-preferences' )
}

function getNotifications()
{
    return axiosCadev1Players.get( '/notifications' )
}

function getNotificationPreferences()
{
    return axiosCadev1Players.get( '/notifications-preferences' )
}

function getProfile()
{
    return axiosCadev1Players.get( '/profile' )
}

function getPersonalInfo()
{
    return axiosCadev1Players.get( '/personal-info' )
}

var output = {}

axios.all( [getAttributes(), getCommunicationPreferences(), getNotifications(), getNotificationPreferences(), getProfile(), getPersonalInfo()] )
    .then( axios.spread( function ( attribs, communicationPreferences, notifications, notifPreferences, profile, persInfo )
    {
        output.attributes = attribs.data
        // output.communicationPreferences = communicationPreferences.data
        // output.notifications = notifications.data
        // output.notifPreferences = notifPreferences.data
        // output.profile = profile.data
        // output.personalInfo = persInfo.data

        console.log( JSON.stringify( output ) )
    } ) )
