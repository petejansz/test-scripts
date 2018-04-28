
var program = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/commander' )
var lib1 = require( process.env.USERPROFILE + "/Documents/bin/lib1.js" )
const fs = require( 'fs' )
const path = require( 'path' )
var util = require( 'util' )

program
    .version( '0.0.1' )
    .description( 'NodeJS CLI to players/self get attributes' )
    .usage( '-f file' )
    .option( '-f, --file [file]', 'filename' )
    .parse( process.argv )

process.exitCode = 1

var objStr = null

if ( program.file )
{
    objStr = fs.readFileSync( path.resolve( program.file ) ).toString()
}
else
{
    var stdinBuffer = fs.readFileSync( 0 ) // STDIN_FILENO = 0
    objStr = stdinBuffer.toString().trim()
}

if ( !objStr )
{
    program.help()
}

var obj = JSON.parse( objStr )

for ( i = 0; i < obj.value.length; i++ )
{
    var item = obj.value[i]
    // if ( item.id.match( /HostEvent/ig ) )//&& item.channels.EMAIL.enabled )
    if ( item.channels.EMAIL.enabled )
    {
        var o2 = {}
        o2.name = item.id
        o2.emailEnabled = item.channels.EMAIL.enabled
        console.log( JSON.stringify( o2 ) )
    }
}
