#  #   !/usr/bin/env python

# -*- coding: utf-8 -*-
"""
This Python 3.7 script:
Uses aiohttp, asyncio, async, await to OAuth login, make other PD REST API calls

Author: Pete Jansz, 2020
"""

import aiohttp
import asyncio
import argparse
import io
import json
import os
import sys

API_BASE_PATH = '/api/v1/players/self/'
ALL_API_NAMES = [
    'attributes', 'communication-preferences', 'notifications',
    'notifications-preferences', 'personal-info', 'profile'
]

CA_SITE_CONSTANTS = {'SITE_ID': '35', 'SYSTEM_ID': '8'}
CA_PD_CONSTANTS = {
        'MOBILE_CLIENT_ID': 'CAMOBILEAPP',
        'PWS_CLIENT_ID': 'SolSet2ndChancePortal',
        'MOBILE_CHANNEL_ID': '3',
        'PWS_CHANNEL_ID': '2'
    }
DEFAULT_ESA_API_KEY = 'di9bJ9MPTXOZvEKAvd7CM8cRJ4Afo54b'

def getCommonHeaders():
    headers = {
        'cache-control': 'no-cache',
        'content-type': 'application/json;charset=UTF-8',
        'connection': 'keep-alive'
    }

    return headers

def createHeaders( hostname ):

    headers = getCommonHeaders()

    headers['x-ex-system-id'] = CA_SITE_CONSTANTS.get('SYSTEM_ID')
    headers['x-site-id'] =  CA_SITE_CONSTANTS.get('SITE_ID')
    headers['x-channel-id'] = CA_PD_CONSTANTS.get('PWS_CHANNEL_ID')

    if hostname.count('mobile') > 0:
        headers['x-channel-id'] = CA_PD_CONSTANTS.get('MOBILE_CHANNEL_ID')

        if os.environ.get('ESA_API_KEY'):
            headers['x-esa-api-key'] = os.environ.get('ESA_API_KEY')
        else:
            headers['x-esa-api-key'] = DEFAULT_ESA_API_KEY

    return headers

def make_uri( endpoint, api_path ):
    return endpoint['proto'] + endpoint['hostname'] + api_path

async def is_available(session, endpoint, args):
    """
    Returns text: "true|false"
    """
    api_path = '/api/v1/players/available/'
    url = make_uri(endpoint, api_path) + args.available
    async with session.get(url) as resp:
        assert resp.status == 200
        return await resp.text()

async def forgotten_password(session, endpoint, args):
    api_path = '/api/v1/players/forgotten-password'
    url = make_uri( endpoint, api_path )
    async with session.put(url, json={'emailAddress': args.forgot}) as resp:
        print( resp.status )

async def get_players_self(session, endpoint, headers, api):
    api_path = API_BASE_PATH + api
    url = make_uri(endpoint, api_path)
    async with session.get(url, headers=headers) as resp:
        return await resp.json()

async def loginForAuthCode(session, endpoint, creds):
    """
    Make OAuth login, return JSON with authCode
    """
    api_path = '/api/v1/oauth/login'
    url = make_uri(endpoint, api_path)
    loginRequest = createLoginRequest(endpoint, creds)
    async with session.post(url, json=loginRequest) as resp:
        return await resp.json()

def createOAuthTokensRequest( authCode, loginRequest ):
    request = {
        'authCode': authCode,
        'clientId': loginRequest.get('clientId'),
        'siteId': loginRequest.get('siteId')
    }

    return request

async def getOAuthTokens(session, endpoint, authCode, loginRequest):
    """
    Using authCode, get JSON with tokens for session use.
    """
    oAuthTokensRequest = createOAuthTokensRequest( authCode, loginRequest )
    api_path='/api/v1/oauth/self/tokens'
    url = make_uri(endpoint, api_path)
    async with session.post(url, json=oAuthTokensRequest) as resp:
        return await resp.json()

def createLoginRequest(endpoint, creds):
    request = { 'siteId': CA_SITE_CONSTANTS.get('SITE_ID') }

    if endpoint.get('hostname').count( 'mobile' ) > 0:
        request['clientId'] = CA_PD_CONSTANTS.get('MOBILE_CLIENT_ID')
    else:
        request['clientId'] = CA_PD_CONSTANTS.get('PWS_CLIENT_ID')

    if creds.get('username') and creds.get('password'):
        request['resourceOwnerCredentials'] = { 'USERNAME': creds.get('username'), 'PASSWORD': creds.get('password') }

    return request

def createArgParser():
    description = 'Python 3.7+ PD API client.'
    description += '\n\n    ENVIRONMENT: ESA_API_KEY default=' + DEFAULT_ESA_API_KEY + '\n'

    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('--api', help='Names: ' + ','.join(ALL_API_NAMES), type=str)
    parser.add_argument('--available', help='Is username available', type=str)
    parser.add_argument('-c', '--count', help='Repeat count times', type=int, default=1)
    parser.add_argument('--hostname', help='Hostname', required=True, type=str)
    parser.add_argument('--forgot', help='Forgot password', type=str)
    parser.add_argument('-o', '--oauth', help='OAuth session token', required=False, type=str)
    parser.add_argument('-p', '--password', help='Password', required=False, type=str)
    parser.add_argument('-q', '--quiet', help='Shhhh', action='store_true')
    parser.add_argument('--reg', help='Register new user', required=False, type=str)
    parser.add_argument('-u', '--username', help='Username',
                        required=False, type=str)
    return parser

def validateCliApiList(parser):
    args = parser.parse_args()

    # Default API names list:
    api_list = ALL_API_NAMES.copy()

    if args.api and len(args.api.split(',')) > 0:
        cli_api_args = args.api.split(',')
        for cli_api_arg in cli_api_args:
            if cli_api_arg not in ALL_API_NAMES:
                parser.print_help()
                exit(1)
        api_list = cli_api_args.copy()

    return api_list


def read_regjson(json_file):
    with open(json_file, 'r') as f:
        return json.load(f)

def create_endpoint(args):
    proto = 'https://'
    hostname = args.hostname

    if args.hostname.count('dev') > 0:
        proto = 'http://'
        if args.hostname.count('.gtech.com') == 0:
            hostname += '.gtech.com'

    endpoint = {'proto': proto, 'hostname': hostname}

    return endpoint

async def main():
    exit_value = 1
    parser = createArgParser()
    args = parser.parse_args()

    if args.hostname == None:
        parser.print_help()
        exit(exit_value)

    endpoint = create_endpoint( args )
    headers = createHeaders(endpoint.get('hostname'))

    async with aiohttp.ClientSession(headers=headers) as clientSession:

        # Login, get token set headers['Authorization']:
        if args.username or args.password or args.oauth:

            resp_dict = {}
            oauth_token = None

            api_list = []
            if args.reg == None:
                api_list = validateCliApiList(parser)

            if args.username and args.password:
                creds = {'username': args.username, 'password': args.password}

                try:
                   resp_dict = await loginForAuthCode(clientSession, endpoint, creds)
                except Exception as e:
                    print(e, file=sys.stderr)
                    exit(exit_value)

                if len(resp_dict) == 3 and resp_dict.get('code') == 'NOT_AUTHENTICATED':
                    print('401: NOT_AUTHENTICATED', file=sys.stderr)
                    exit(exit_value)

                if len(resp_dict) == 1 and resp_dict[0].get('authCode') != None:
                    authCode = resp_dict[0].get('authCode')
                    loginRequest = createLoginRequest(endpoint, creds)

                    try:
                        resp_dict = await getOAuthTokens(clientSession, endpoint, authCode, loginRequest)
                        if endpoint.get('hostname').count('mobile') > 0:
                            oauth_token = resp_dict[0].get('token')
                        else:
                            oauth_token = resp_dict[1].get('token')
                    except Exception as e:
                        print(e, file=sys.stderr)
                        exit(exit_value)
            elif args.oauth:
                oauth_token = args.oauth

            headers['Authorization'] = 'OAuth ' + oauth_token

            tasks = []
            for i in range(0, args.count):
                for api in api_list:
                    tasks.append( get_players_self(clientSession, endpoint, headers, api) )

            responses = await asyncio.gather(*tasks)

            objects = []
            for resp_dict in responses:
                objects.append(resp_dict)

            if len(objects) == 1 : objects = objects[0]

            if not args.quiet:
                print(json.dumps(objects, indent=4))

            exit_value = 0

        else:  # Anonymous
            if args.available:
                resp = await is_available(clientSession, endpoint, args)
                print(resp)
                exit_value = 0
            elif args.forgot:
                await forgotten_password(clientSession, endpoint, args)
                exit_value = 0

    exit(exit_value)

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
    loop.run_until_complete(asyncio.sleep(0.250))
    loop.close()
