// Test GET /api/v2/draw-games/draws against hostnames

var http = require( "https" )
var util = require( "util" )
var peteUtil = require( 'pete-lib/pete-util' )

const PATH = '/api/v2/draw-games/draws'
var hostnames =
    [
        'cat-draw-mobile.calottery.com',
        'sit-draw-mobile.calottery.com'
    ]

process.exitCode = 0

for ( var a = 1; a < 3; a++ )
{
    for ( var i = 0; i < hostnames.length; i++ )
    {
        var hostname = hostnames[i]
        testIt( hostname, a )
    }
}

function testIt( hostname, testNr )
{
    var options =
        {
            "method": "GET",
            "hostname": hostname,
            "port": null,
            "path": PATH,
            "headers": peteUtil.commonHeaders
        }

    var req = http.request( options, function ( res )
    {
        var chunks = []

        res.on( "data", function ( chunk )
        {
            chunks.push( chunk )
        } )

        res.on( "end", function ()
        {
            var body = Buffer.concat( chunks )
            var responseObj =
                {
                    headers: this.headers,
                    statusCode: this.statusCode,
                    statusMessage: this.statusMessage,
                    body: body
                }

            if ( responseObj.statusCode != 200 )
            {
                process.exitCode = 1
                console.error( util.format( '%s: %s', testNr, hostname ) )
                console.error( JSON.stringify( responseObj ) )
            }
        } )
    } )

    req.end()
}