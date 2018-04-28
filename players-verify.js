var fs = require( "fs" );
var http = require( "http" );
var program = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/commander' );
var lib1 = require( process.env.USERPROFILE + "/Documents/bin/lib1.js" );

program
    .version( '0.0.1' )
    .description( 'CLI to players/verifiy/{code} REST method' )
    .usage( 'players-verify.js [option] -h <hostname>' )
    .option( '-c, --code code', 'Code' )
    .option( '-h, --hostname <hostname>', 'Hostname' )
    .parse( process.argv );

var exitValue = 0;
var code = null;

if ( !program.hostname )
{
    program.help();
    process.exit( 1 );
}

if ( program.code )
{
    code = program.code;
}
else
{
    var stdinBuffer = fs.readFileSync( 0 ); // STDIN_FILENO = 0
    code = stdinBuffer.toString().trim();
}

var options =
{
    "method": "GET",
    "hostname": program.hostname,
    "port": null,
    "path": "/api/v1/players/verify/" + code,
    "headers": lib1.commonHeaders
};

var req = http.request( options, function ( res )
{
    var chunks = [];

    res.on( "data", function ( chunk )
    {
        chunks.push( chunk );
    } );

    res.on( "end", function ()
    {
        var body = Buffer.concat( chunks );
        console.log( body.toString() );
    } );
} );

req.end();