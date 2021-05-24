#   !/usr/bin/env python

# -*- coding: utf-8 -*-
"""
This Python 3 script demonstrates:
1. Use of arparse to manage CLI options, flags, interface
2. Consume (GET) a REST API
3. print_format {}
4. Convert long time epoch time to readable format

Author: Pete Jansz, 2019
"""

import argparse
from casite import casite
from datetime import datetime
import os.path
import json
import requests
import sys

caSite = None

def create_headers():
    headers = {
        'accept': '*/*',
        'user-agent': os.path.basename(__file__),
        'cache-control': 'no-cache',
        'content-type': 'application/json'
    }

    return headers

def query(args):
    host, query_str = args.host, args.qs
    apiPath = 'api/v2/draw-games/draws'

    # Default params
    params = {'exclude-prize-tiers': 'TRUE', 'game-names': args.gamename}

    if query_str != None:
        for kv_pair in query_str.split('&'):
            key, value = kv_pair.split('=')
            params[key] = value

    # Build query string from params:
    qs = ''
    for k, v in params.items(): qs += '&' + k + '=' + v

    proto = 'https'
    uri = ''

    if host.count('.com'):
        uri = "{}://{}/{}".format(proto, host, apiPath)
    else:
        proto = 'http'
        port = 8680
        uri = "{}://{}:{}/{}".format(proto, host, port, apiPath)

    print( uri +  '?' + qs )
    headings = 'NAME      ID  STATUS       CLOSE_TIME        DRAW_TIME'
    print_format = "{} {} {:>7} {:%Y-%m-%d-%H:%M} {:%Y-%m-%d-%H:%M}"
    response = requests.get(uri, params, headers=create_headers(), timeout=10000)

    if (response.ok):
        drawsDict = response.json()
        draws = drawsDict['draws']
        print(headings)

        for draw in draws:
            closeTime = draw['closeTime']
            print(print_format.format(
                draw['gameName'],
                draw['id'],
                draw['status'],
                convertToDatetime(draw['closeTime']),
                convertToDatetime(draw['drawTime'])
            ))

def convertToDatetime(longEpoch):
    dt = None

    if longEpoch % 1000 == 0:
        dt = datetime.fromtimestamp(longEpoch / 1000)
    else:
        dt = datetime.fromtimestamp(longEpoch)

    return dt

def createArgParser():
    parser = argparse.ArgumentParser(description='Check draw-games')
    parser.add_argument('--envname', help='Environment name',
                        required=False, type=str, choices=caSite.gamesenvs())
    parser.add_argument(
        '--host', help='Hostname or IP address', required=False, type=str, choices=caSite.gamesvhosts())
    parser.add_argument('-g', '--gamename', help='Game name (default=KENO', default='KENO',
                        required=False, type=str, choices=caSite.gameNames())
    parser.add_argument('-q', '--qs', help='Query string',
                        required=False, type=str)

    return parser

def main():
    exit_value = 1
    global caSite
    caSite = casite.CalifSite()
    parser = createArgParser()
    args = parser.parse_args()

    if args.host == None and args.envname == None:
        parser.print_help()
        exit(exit_value)
    if args.envname:
        args.host = caSite.gamesvhost(args.envname)

    query(args)

    exit_value = 0

    sys.exit(exit_value)

if __name__ == "__main__":
    main()
