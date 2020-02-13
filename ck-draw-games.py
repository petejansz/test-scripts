#  #   !/usr/bin/env python

# -*- coding: utf-8 -*-
"""
This Python 3 script demonstrates:
1. Use of arparse to manage CLI options, flags, interface
2. Consume (GET) a REST API
3. print_format {}
4. Convert long time epoch time to readable format

Author: Pete Jansz, 2019
"""

import argparse, json, requests, sys
from datetime import datetime

def query(proto, host, port, query_str):
    apiPath = 'api/v2/draw-games/draws'
    params = {'exclude-prize-tiers': 'TRUE', 'game-names': 'KENO'}

    if query_str != None:
        for kv_pair in query_str.split('&'):
            key, value = kv_pair.split('=')
            params[key] = value

    qs = ''
    for k, v in params.items(): qs += '&' + k + '=' + v

    uri = ''
    if port == None:
        uri = "{}://{}/{}".format(proto, host, apiPath)
    else:
        uri = "{}://{}:{}/{}".format('http', host, port, apiPath)

    print( uri +  '?' + qs )
    headings = 'NAME      ID  STATUS       CLOSE_TIME        DRAW_TIME'
    print_format = "{} {} {:>7} {:%Y-%m-%d-%H:%M} {:%Y-%m-%d-%H:%M}"
    response = requests.get( uri, params )

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
    parser.add_argument(
        '--proto', help='Protocol', default='https', choices=['http', 'https'], required=False, type=str)
    parser.add_argument(
        '--host', help='Hostname or IP address', required=True, type=str)
    parser.add_argument('--port', help='port', required=False, type=int)
    parser.add_argument('-q', '--qs', help='Query string',
        required=False, type=str)

    return parser

def main():
    exit_value = 1

    args = createArgParser().parse_args()

    query(args.proto, args.host, args.port, args.qs)

    exit_value = 0

    sys.exit(exit_value)

if __name__ == "__main__":
    main()
