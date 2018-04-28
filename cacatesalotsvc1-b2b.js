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
    .option( '--host [hostname]', 'Hostname default = cacatesalotsvc1' )
    .option( '--port [port]', 'Port number default = 80', parseInt )
    .option( '--gamename [gamename]', 'default = KENO' )
    .option( '--datefrom [datefrom]' )
    .option( '--dateto [dateto]' )
    .option( '--delimited [delimited]' )
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

//qsArgs.status = 'PAYABLE'
qsArgs['exclude-prize-tiers'] = 'TRUE'
//qsArgs['previous-draws'] = 300
// qsArgs['end-draw'] = 23399
// qsArgs['start-draw'] = 23699
// console.log( 'qsArgs: ' + JSON.stringify( qsArgs ) )
var host = program.host ? program.host : 'cacatesalotsvc1'

var options = {
    method: 'GET',
    url: 'http://' + host + '/api/v2/draw-games/draws',
    rejectUnauthorized: false, // Prevents Error: Hostname/IP doesn't match certificate's altnames: "IP: 204.214.50.24 is not in the cert's list: "
    qs: qsArgs,
    headers: lib1.commonHeaders
}

request( options, function ( error, response, body )
{
    if ( error ) throw new Error( error )

    if ( !program.delimited )
    {
        console.log( lib1.formatJSON( body ) )
    }
    else
    {
        var json = JSON.parse( body )
        for ( var i = 0; i < json.draws.length; i++ )
        {
            var count = i+1
            var draw = json.draws[i]
            var drawStr = util.format( '%s: %s%s%s%s%s', count, draw.id, program.delimited, draw.status, program.delimited, new Date( draw.closeTime ) )
            console.log( drawStr )
        }
    }
    process.exitCode = 0
} )
