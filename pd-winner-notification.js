#!/usr/bin/env node

/*
  NodeJS command-line interface trigger a winner-notification from the crm-core:8280/california-adapter REST api
  Author: Pete Jansz
*/

var program = require( 'commander' )
var igtPdLib = require( 'pete-lib/igt-pd-lib' )
var igtCas = require( 'pete-lib/igt-cas' )
const axios = require( 'axios' )
const CRM_CORE_HTTP_PORT = 8280
const BASE_REST_PATH = '/california-adapter/api/v1'

program
    .version( '0.0.1' )
    .description( 'CLI to trigger a winner-notification' )
    .usage( ' -h <crm-core> -i <playerid> -e email' )
    .option( '-e, --email <email>', 'user emailname' )
    .option( '-h, --host <host>', 'crm-core host' )
    .option( '-i, --playerid <playerid>', 'Player ID', parseInt )
    .option( '--getuuid')
    .parse( process.argv )

process.exitCode = 1

if ( !program.playerid || !program.host || !program.email )
{
    program.help()
}

var moreHeaders =
{
    'x-channel-id': igtCas.getChannelId(),
    'x-client-id': "Portal",
    'x-ex-system-id': igtCas.getSystemId(),
    'x-site-id': igtCas.getSiteId()
}

var request =
{
    playerId: program.playerid,
    emailName: program.email,
    description: 'some_description',
    includeFooter: false,
    templateParameters: {},
    eventTypeName: 'WinnerNotification'
}

var restPath = 'http://' + program.host + ':' + CRM_CORE_HTTP_PORT + BASE_REST_PATH+ '/notifications'
createAxiosInstance( program.host, program.playerid, moreHeaders ).
    post( restPath, request ).then( function ( response )
    {
        if ( response.data.errorEncountered )
        {
            console.error( response.data )
        }
        else
        {
            program.getuuid ? console.log(response.headers['x-unique-id']) : 0
            process.exitCode = 0
        }
    } )

function createAxiosInstance( host, playerId, moreHeaders )
{
    var headers = igtPdLib.getCommonHeaders()
    headers['x-player-id'] = playerId

    if ( moreHeaders )
    {
        for ( var key in moreHeaders )
        {
            headers[key] = moreHeaders[key]
        }
    }

    return axios.create(
        {
            baseURL: 'http://' + host + ':' + CRM_CORE_HTTP_PORT,
            headers: headers,
        }
    )
}
