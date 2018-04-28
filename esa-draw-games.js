var str_to_stream = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/string-to-stream' )
var request = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/request' )
var program = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/commander' )
var lib1 = require( process.env.USERPROFILE + "/Documents/bin/lib1.js" )
var util = require('util')

program
    .version( '0.0.1' )
    .description( '' )
    .usage( 'ARGS' )
    .option( '--host [hostname]', 'Hostname' )
    .option( '--port [port]', 'Port number', parseInt )
    .option( '--reqid [reqid]', 'x-request-id', parseInt )
    .option( '--origid [origid]', 'x-originator-id', parseInt )
    .option( '--siteid [siteid]', 'x-site-id' )
    .option( '--chid [chid]', 'x-channel-id', parseInt )
    .option( '--sysid [sysid]', 'x-ex-system-id', parseInt )
    .option( '--barcode [barcode]', 'barcode' )
    .parse( process.argv )

process.exitCode = 1

var wvsDev = {"host": '10.17.30.170', "port": 8580}
var restPath = '/api/v2/draw-games/draws'
var host = program.host? program.host : wvsDev.host
var port = program.port? program.port : wvsDev.port

var url = util.format('http://%s:%s%s', host, port, restPath)

var options = {
    method: 'GET',
    url: url,
    headers:
        {
            'cache-control': 'no-cache',
            'x-request-id': '12312312',
            'x-originator-id': '7',
            'x-site-id': '085',
            'x-channel-id': '2',
            'x-ex-system-id': '8',
            'content-type': 'application/json'
        },
//    body: { barcode: '44029871005000098275285983' },
    json: true
}

process.exitCode = 1

request( options, function ( error, response, body )
{
    if ( error ) throw new Error( error )

    process.exitCode = 0

    str_to_stream( lib1.formatJSON( JSON.stringify(response) ) ).pipe( process.stdout )
} )
