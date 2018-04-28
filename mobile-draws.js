// Test GET /api/v2/draw-games/draws against hostnames

var http = require( "https" )
var util = require( "util" )
var lib1 = require( process.env.USERPROFILE + "/Documents/bin/lib1.js" )

const PATH = '/api/v2/draw-games/draws'
var hostnames =
    [
        'ca-cat-b2b.lotteryservices.com',
        'mobile-cat.calottery.com',
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
            "headers": lib1.commonHeaders
        }

    options.headers.accept = 'application/json, text/javascript, */*; q=0.01'
    options.headers['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36'

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
                console.err( util.format( '%s: %s', testNr, hostname ) )
                console.error( JSON.stringify( responseObj ) )
            }
        } )
    } )

    req.end()
}