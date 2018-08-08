/**
 * Get draw-games
 */
var path = require( 'path' )
var util = require( 'util' )
var request = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/request' )
var program = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/commander' )
var str_to_stream = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/string-to-stream' )
var stream_to_str = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/stream-to-string' )
var lib1 = require( process.env.USERPROFILE + '/Documents/bin/lib1.js' )

program
    .version( '0.0.1' )
    .description( 'ESA B2B draw-games' )
    .usage( 'ARGS' )
    .option( '--proto-host [protoHost]', 'Hostname default = http://mobile-cat.calottery.com' )
    .option( '--port [port]', 'default=80', parseInt )
    .option( '--gamename [gamename]', 'default = KENO' )
    .option( '--datefrom [datefrom]' )
    .option( '--dateto [dateto]' )
    .option( '--size [size]', parseInt )
    .option( '--delimited [delimited]' )
    .option( '--origid [originatorid]', 'x-originator-id (10002,1,1,0)' )
    .option( '--reqid [requestid]', 'x-request-id: (1234567890,0)' )
    .option( '--siteid [siteid]', 'x-site-id (CAS 35)' )
    .parse( process.argv )

process.exitCode = 1
// if ( !program.host )
// {
//     program.help()
// }

var qsArgs =
    {
        'game-names': program.gamename ? program.gamename : 'KENO'
    }

if ( program.datefrom )
{
    var dt = program.datefrom.match( /^\d+$/ ) ? parseInt( program.datefrom ) : program.datefrom
    qsArgs['date-from'] = new Date( dt ).getTime()
}

if ( program.dateto )
{
    var dt = program.dateto.match( /^\d+$/ ) ? parseInt( program.dateto ) : program.dateto
    qsArgs['date-to'] = ( new Date( dt ).getTime() )
}

if ( program.size )
{
    qsArgs['size'] = program.size
}

//qsArgs.status = 'PAYABLE'
qsArgs['exclude-prize-tiers'] = 'TRUE'
//qsArgs['previous-draws'] = 300
// qsArgs['end-draw'] = 23399
// qsArgs['start-draw'] = 23699
// console.log( 'qsArgs: ' + JSON.stringify( qsArgs ) )

var protoHost = program.protoHost ? program.protoHost : 'http://mobile-cat.calottery.com'
restPath = '/api/v2/draw-games/draws'
var url = protoHost + restPath
if (program.port)
{
    url = protoHost + ':' + program.port + restPath
}

var options =
{
    method: 'GET',
    url: url,
    // Prevents Error: Hostname/IP doesn't match certificate's altnames: "IP: 204.214.50.24 is not in the cert's list: "
    rejectUnauthorized: false,
    qs: qsArgs,
    headers: lib1.commonHeaders
}

var terminalNr = "10002"
options.headers['user-agent'] = 'CASA-test'
if (program.origid)
{
    options.headers['x-originator-id'] = program.origid
}
else
{
    options.headers['x-originator-id'] = terminalNr + ',1,1,0'
}

if (program.reqid)
{
    options.headers['x-request-id'] = program.reqid
}
else
{
    options.headers['x-request-id'] = '1234567890,0'
}

if (program.siteid)
{
    options.headers['x-site-id'] = program.siteid
}
else
{
    options.headers['x-site-id'] = lib1.caConstants.siteID
}

console.error( options )

request( options, function ( error, response, body )
{
    if ( error ) {throw new Error( error )}

    if ( !program.delimited )
    {
        console.log( lib1.formatJSON(body) )
    }
    else
    {
        var json = JSON.parse( body )
        for ( var i = 0; i < json.draws.length; i++ )
        {
            var count = i + 1
            var draw = json.draws[i]
            var drawStr = util.format( '%s: %s%s%s%s%s',
                count, draw.id, program.delimited, draw.status, program.delimited, new Date( draw.closeTime ) )
            console.log( drawStr )
        }
    }

    process.exitCode = 0
} )
