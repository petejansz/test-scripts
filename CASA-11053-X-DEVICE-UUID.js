var http = require( "http" )
var program = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/commander' )
var lib1 = require( process.env.USERPROFILE + "/Documents/bin/lib1.js" )
const fs = require( 'fs' )
var util = require( 'util' )

program
    .version( '0.0.1' )
    .description( 'NodeJS CLI to /api/v1/second-chance/players/self/submissions' )
    .usage( '--hostname <host>' )
    .option( '--hostname <hostname>', 'Hostname' )
    // .option( '-u, --username [username]', 'Username' )
    // .option( '-p, --password [password]', 'Password' )
    .parse( process.argv )

process.exitCode = 1

if ( !program.hostname )
{
    program.help()
}

var options = {
    "method": "POST",
    "hostname": program.hostname, //"ca-cat2-mobile.lotteryservices.com",
    "port": program.port ? program.port : null,
    "path": "/api/v1/second-chance/players/self/submissions",
    "headers": {
        "content-type": "application/json",
        "x-ex-system-id": "8",
        "x-channel-id": "3",    // mobile
        "x-site-id": "35",
        "x-esa-api-key": "DBRDtq3tUERv79ehrheOUiGIrnqxTole",
        "x-method": "scan",
        "authorization": "OAuth b45jm5oNkEh7YaKSCUeYcg",
        "x-device-uuid": "abcd1",
        "cache-control": "no-cache",
        "postman-token": "7f4b2af2-053e-1cb5-d662-58ede2f6ad6e"
    }
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
        console.log( body.toString() )
    } )
} )

req.write( JSON.stringify( {
    type: '.ScratcherSubmissionDTO',
    entryCode: '10158395255420000002',
    ticketId: ''
} ) )
req.end()
