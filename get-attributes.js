/**
 * NodeJS CLI to players/self get attributes.
 * Demonstrates use of request-promise, accepting oauth token from stdin,
 *  making synchronous (async/await) a promised function
 * Pete Jansz Dec 2017
 */

const modulesPath = '/usr/share/node_modules/'
var request = require( modulesPath + 'request-promise' )
var program = require( modulesPath + 'commander' )
var peteUtil = require( modulesPath + 'pete-lib/pete-util' )
const fs = require( 'fs' )
var util = require( 'util' ) // to support async/await(promised-func)

program
    .version( '0.0.1' )
    .description( 'NodeJS CLI to players/self get attributes' )
    .usage( '-h <host> [-u username -p password]' )
    .option( '-h, --hostname <hostname>', 'Hostname' )
    .option( '-u, --username [username]', 'Username' )
    .option( '-p, --password [password]', 'Password' )
    .parse( process.argv )

process.exitCode = 1

if ( !program.hostname )
{
    program.help()
}

var authToken = null

if ( program.username && program.password )
{
    authToken = peteUtil.getOAuthToken( program.hostname, program.username, program.password )
}
else
{
    var stdinBuffer = fs.readFileSync( 0 ) // STDIN_FILENO = 0
    authToken = stdinBuffer.toString().trim()
}

async function main()
{
    var attributesStr = await getAttributes( program.hostname, authToken )
    console.log( JSON.stringify( JSON.parse( attributesStr ), null, 4 ) )
    process.exitCode = 0
}

main()

// Return a promise or synchronusly write to responseStream
function getAttributes( hostname, authToken, responseStream )
{
    var urlFormat = 'http://%s/api/v1/players/self/attributes'
    var url = util.format( urlFormat, hostname )
    var options =
        {
            method: 'GET',
            url: url,
            headers: peteUtil.commonHeaders
        }
    options.headers.authorization = "OAuth " + authToken

    if ( responseStream )
    {
        request( options ).pipe( responseStream )
    }
    else
    {
        return request( options )
    }
}
