/**
 * Author: Pete Jansz
 */

var path = require( 'path' )
var util = require( 'util' )
var request = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/request' )
var program = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/commander' )
var str_to_stream = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/string-to-stream' )
var stream_to_str = require( process.env.USERPROFILE + '/AppData/Roaming/npm/node_modules/stream-to-string' )
var lib1 = require( process.env.USERPROFILE + '/Documents/bin/lib1.js' )
var SITES = { OR: 11 }
const BC_FORMAT = 'GGGGGPPPPPPTTTVVVVVVVVVCLLLL'

program
    .version( '0.0.1' )
    .description( 'ESA B2B draw or instant ticket inquiry\n  Parse, format and print instant barcode' )
    .usage( 'ARGS' )
    .option( '--host [hostname]', 'Hostname' )
    .option( '--port [port]', 'Port number', parseInt )
    .option( '--instant', 'Default is draw' )
    .option( '--print', 'Parse and format and print' )
    .option( '--ticket <ticket>', 'ticket s/n,', [] )
    .option( '--originator [originator]', 'x-originator-id (7)' )
    .option( '--siteid [siteid]', 'x-site-id (Oregon 11)' )
    .parse( process.argv )

process.exitCode = 1

if ( !program.ticket )
{
    program.help()
}

for ( var i = 0; i < process.argv.length; i++ )
{
    var argv = process.argv[i]
    if ( argv.match( /^[0-9]{28}$|^\d{5}[\-]\d*$/ ) )
    {
        var ticket = argv
        main( program, ticket )
    }
}

function main( progArgs, ticket )
{
    if ( progArgs.instant && progArgs.print )
    {
        var sep = '-'
        var formattedBcStr = formatBarcode( parseBarcode( BC_FORMAT ), sep )
        var formattedStr = formatBarcode( parseBarcode( ticket ), sep )
        console.log( formattedBcStr + "\n" + formattedStr )
    }

    if ( progArgs.host )
    {
        var port = progArgs.port ? progArgs.port : 8580
        var games = progArgs.instant ? 'instant-games' : 'draw-games'
        var options = {
            method: 'POST',
            url: "http://" + progArgs.host + ":" + port + "/api/v1/" + games + "/tickets/inquire",
            headers:
                {
                    'cache-control': 'no-cache',
                    'x-request-id': '123123',
                    'x-originator-id': progArgs.originator ? progArgs.originator : 7,
                    'x-site-id': progArgs.siteid ? progArgs.siteid : SITES.OR,
                    'content-type': 'application/json'
                },
            json: true
        }

        if ( progArgs.instant )
        {
            var barcode = parseBarcode( ticket )
            options.body = { barcode: formatBarcode( barcode, '' ) }
            console.log( formatBarcode( barcode, '-' ) )
        }
        else
        {
            options.body = { ticketSerialNumber: ticket }
        }

        request( options, function ( error, response, body )
        {
            if ( error ) throw new Error( error )

            process.exitCode = 0
            console.log( JSON.stringify( body ) )
        } )
    }
}

function formatBarcode( barcode, sep )
{
    var gameId = barcode.gameId
    var packId = barcode.packId
    var ticketNr = barcode.ticketNr
    var virn1 = barcode.virn1
    var virn2 = barcode.virn2
    var pin = barcode.pin

    var formatStr = '%s' + sep + '%s' + sep + '%s' + sep + '%s' + sep + '%s' + sep + '%s'
    return util.format( formatStr, gameId, packId, ticketNr, virn1, virn2, pin )
}

// Acceptable patterns:
//  GGGGGPPPPPPTTTVVVVVVVVVCLLLL
//  Embedded '-' or space-char any where
function parseBarcode( barcodeString )
{
    var barcode =
        {
            gameId: null,
            packId: null,
            ticketNr: null,
            virn1: null,
            virn2: null,
            pin: null
        }

    if ( barcodeString != null )
    {
        barcodeString = barcodeString.replace( / |\-/g, '' )
        if ( barcodeString.length == 28 )
        {
            barcode =
                {
                    gameId: barcodeString.substring( 0, 5 ),
                    packId: barcodeString.substring( 5, 11 ),
                    ticketNr: barcodeString.substring( 11, 14 ),
                    virn1: barcodeString.substring( 14, 23 ),
                    virn2: barcodeString.substring( 23, 24 ),
                    pin: barcodeString.substring( 24 )
                }
        }
    }

    return barcode
}