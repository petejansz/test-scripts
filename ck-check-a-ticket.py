#!/bin/env python

"""
  Check CA Check-a-ticket Can be used from gateway (rengw2, ...) or PC to check the status, draws, ticket inquiry.
  Requires Python 2.6
  Author: Pete Jansz
  Initial version date: 2021-05-19
"""

import httplib
import json
import os.path
import ssl
import string
import sys
import time
import uuid
from optparse import OptionParser

parser = OptionParser()
CA_SITE_CONSTANTS = {'SITE_ID': '35', 'SYSTEM_ID': '8',
                     'MOBILE_CHANNEL_ID': '3', 'PWS_CHANNEL_ID': '2'}
REST_PATHS = {'draw-inquiry': '/api/v2/draw-games/tickets/inquire',
              'instant-inquiry': '/api/v1/instant-games/tickets/inquire',
              'draw-info': '/api/v2/draw-games/draws', 'status': '/esa/status'}
LOTSERVER_PORT = 8680

def parse_cli_args():
    parser.description = 'Check CA Check-A-Ticket. Perform ticket inquiry, get draw-game info.'
    parser.add_option('--host', type='string', dest='host', help='Hostname or IP address')
    parser.add_option('-d', '--draws', type='string', dest='game_names', action='append', help='Draw game draw info, e.g,keno,daily3')
    parser.add_option('--status', action='store_true', dest='status', help='ESA gateway status')
    parser.add_option('-t', '--tickets', type='string', dest='tickets', action='append', help='Instant, draw ticket inquiry')
    return parser.parse_args()

def create_connection(options):
    conn = None

    if options.host.count('.com'):
        conn = httplib.HTTPSConnection(
            options.host, context=ssl._create_unverified_context())
    else:
        conn = httplib.HTTPConnection(options.host, port=LOTSERVER_PORT)

    return conn

def get_drawgames_draws(conn, options):
    qs_params = 'exclude-prize-tiers=TRUE'

    for name in options.game_names:
        qs_params += '&game-names=' + name.upper()

    restPath = '%s?%s' % (REST_PATHS['draw-info'], qs_params)
    conn.request('GET', restPath, headers=create_headers(options))
    httplibResponse = conn.getresponse()
    return convertHttplibResponseToMyResponse(options, httplibResponse)

def check_esa_gateway_status(conn, options):
    headers = {
        'accept': '*/*',
        'user-agent': os.path.basename(__file__),
    }

    conn.request('GET', REST_PATHS['status'], headers=headers)
    httplibResponse = conn.getresponse()
    return convertHttplibResponseToMyResponse(options, httplibResponse)

def create_headers(options):
    channel = '10002'
    linq3_id = '77'
    current_ts = str(int(round(time.time() * 1000)))
    if options.host.count('pws'):
        channel_id = CA_SITE_CONSTANTS['PWS_CHANNEL_ID']
    else:
        channel_id = CA_SITE_CONSTANTS['MOBILE_CHANNEL_ID']

    headers = {
        'accept': '*/*',
        'user-agent': os.path.basename(__file__),
        'cache-control': 'no-cache',
        'content-type': 'application/json',
        'x-originator-id': channel + ',6,7,8',
        'x-request-id': '%s,%s' % (linq3_id, current_ts),
        'x-site-id': CA_SITE_CONSTANTS['SITE_ID'],
        'x-channel-id': channel_id,
        'x-ex-system-id': CA_SITE_CONSTANTS['SYSTEM_ID'],
        'x-device-uuid': uuid.uuid4()
    }

    return headers

def convertHttplibResponseToMyResponse(options, httplibResponse, ticket=None):
    myResponse = {'responseCode': httplibResponse.status,
                  'reason': httplibResponse.reason}

    if ticket:
        myResponse['ticket'] = ticket

    if options.status:
        myResponse['data'] = httplibResponse.read()
    else:
        myResponse['data'] = json.loads(httplibResponse.read())

    return myResponse

def do_ticket_inquiries(conn, options):

    responseObjects = []

    for ticket in options.tickets:

        headers = create_headers(options)

        if not ticket.isdigit() and len(ticket) == 13:
            body = '{"ticketSerialNumber": "%s"}' % ticket
            conn.request('POST', REST_PATHS['draw-inquiry'], body=body, headers=headers)
        else:
            body = '{"barcode": "%s"}' % ticket
            conn.request(
                'POST', REST_PATHS['instant-inquiry'], body=body, headers=headers)

        httplibResponse = conn.getresponse()
        myResponse = convertHttplibResponseToMyResponse(
            options, httplibResponse, ticket)
        responseObjects.append(myResponse)

    return responseObjects

def main():
    exit_value = 1
    options, args = parse_cli_args()

    if not options.tickets and not options.status and not options.game_names:
        parser.print_help()
        sys.exit(exit_value)

    conn = None

    try:
        conn = create_connection(options)

        if options.status:
            myResponseObject = check_esa_gateway_status(conn, options)
        elif options.game_names:
            myResponseObject = get_drawgames_draws(conn, options)
        elif options.tickets:
            myResponseObject = do_ticket_inquiries(conn, options)

        if options.status:
            for line in myResponseObject['data'].splitlines():
                print(line)
        else:
            print(json.dumps(myResponseObject, indent=2))

        exit_value = 0

    except Exception as error:
        errtype, value, traceback = sys.exc_info()
        sys.stderr.write(str(value))
    finally:
        if conn: conn.close()

    sys.exit(exit_value)

if __name__ == "__main__":
    main()
