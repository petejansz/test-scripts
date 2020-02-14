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
import json

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
API_KEY = 'di9bJ9MPTXOZvEKAvd7CM8cRJ4Afo54b'

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
        headers['x-esa-api-key'] = API_KEY

    return headers

def make_uri( endpoint, api_path ):
    return endpoint['proto'] + endpoint['hostname'] + api_path

async def is_available(session, endpoint, creds):
    """
    Returns text: "true|false"
    """
    api_path = '/api/v1/players/available/'
    url = make_uri(endpoint, api_path) + creds['username']
    async with session.get(url) as resp:
        assert resp.status == 200
        return await resp.text()

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
    parser = argparse.ArgumentParser(description='Python 3.7+ PD API client')
    parser.add_argument('--hostname', help='Hostname', required=True, type=str)
    parser.add_argument( '-c', '--count', help='Repeat count times', type=int, default=1 )
    parser.add_argument('-u', '--username', help='Username', required=True, type=str)
    parser.add_argument('-p', '--password', help='Password', required=True, type=str)
    parser.add_argument('--api', help='Names: ' + ','.join(ALL_API_NAMES), type=str)
    parser.add_argument('-q', '--quiet', help='Shhhh', action='store_true')
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

async def main():
    exit_value = 1

    parser = createArgParser()
    args = parser.parse_args()

    if args.hostname == None or args.username == None:
        parser.print_help()
        exit(exit_value)

    api_list = validateCliApiList(parser)

    proto = 'https://'
    if args.hostname.find('dev') > 0:
        proto = 'http://'

    endpoint = {'proto': proto, 'hostname': args.hostname}
    creds = {'username': args.username, 'password': args.password}
    headers = createHeaders(endpoint.get('hostname'))

    async with aiohttp.ClientSession(headers=headers) as clientSession:

        # Login, get token set headers['Authorization']:
        resp_dict = await loginForAuthCode(clientSession, endpoint, creds)
        if len(resp_dict) == 1 and resp_dict[0].get('authCode') != None:
            authCode = resp_dict[0].get('authCode')
            loginRequest = createLoginRequest(endpoint, creds)
            resp_dict = await getOAuthTokens(clientSession, endpoint, authCode, loginRequest)
            mobileToken = resp_dict[0].get('token')
            pwsToken = resp_dict[1].get('token')

            if endpoint.get('hostname').count('mobile') > 0:
                headers['Authorization'] = 'OAuth ' + mobileToken
            else:
                headers['Authorization'] = 'OAuth ' + pwsToken

            objects = []
            for i in range(0, args.count):
                responses = []
                for api in api_list:
                    resp_dict = await get_players_self(clientSession, endpoint, headers, api)
                    responses.append( resp_dict )

                objects.append(responses)

            if not args.quiet:
                print(json.dumps(objects, indent=4))

            exit_value = 0

        exit(exit_value)

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
    loop.run_until_complete(asyncio.sleep(0.250))
    loop.close()
