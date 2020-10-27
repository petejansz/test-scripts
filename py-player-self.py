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

async def activate_account(session, endpoint, args):
    api_path = '/api/v2/players/activate-account/'

    token = str(args.activate)
    if token.count('code='):
        rubbish, token = token.split('=')
        token = token.strip()

    url = make_uri(endpoint, api_path) + token
    headers = createHeaders( args.hostname )
    async with session.post( url, headers=headers, json={} ) as resp:
        print(resp.status)

async def change_password(session, endpoint, headers, args):
    api_path = '/api/v2/players/self/password'
    url = make_uri(endpoint, api_path)
    async with session.put(url, headers=headers, json={'oldPassword': args.chpwd, 'newPassword': args.newpwd}) as resp:
        print(resp.status)

async def forgotten_password(session, endpoint, args):
    api_path = '/api/v1/players/forgotten-password'
    url = make_uri(endpoint, api_path)
    async with session.put(url, json={'emailAddress': args.forgot}) as resp:
        print(resp.status)

async def is_available(session, endpoint, args):
    """
    Returns text: "true|false"
    """
    api_path = '/api/v1/players/available/'
    url = make_uri(endpoint, api_path) + args.available
    async with session.get(url) as resp:
        assert resp.status == 200
        return await resp.text()

async def lock_service(session, endpoint, headers, lock):
    api_path = '/api/v1/players/self/lock-service'
    reason = 'To lock or unlock, that is the question.'
    url = make_uri(endpoint, api_path)
    async with session.put(url, headers=headers, json={'lockPlayer': lock, 'reason': reason}) as resp:
        print(resp.status)


async def logout(session, endpoint, headers, outh_token):
    api_path = '/api/v1/oauth/logout'
    url = make_uri(endpoint, api_path)
    async with session.delete(url, headers=headers, json={'token': outh_token, 'tokenType': 'OAuth'}) as resp:
        print(resp.status)

async def reset_password(session, endpoint, args):
    api_path = '/api/v2/players/reset-password'
    onetimeToken = args.resetpwd
    url = make_uri(endpoint, api_path)
    headers = createHeaders( args.hostname )
    async with session.put( url, headers=headers, json={'newPassword': args.newpwd, 'oneTimeToken': onetimeToken} ) as resp:
        print(resp.status)

async def resend_activation_mail(session, endpoint, headers):
    api_path = '/api/v2/players/self/activation-mail'
    url = make_uri(endpoint, api_path)
    async with session.put(url, headers=headers, json={}) as resp:
        print(resp.status)

async def unsubscribe_event(session, endpoint, args):
    api_path = '/api/v1/notifications/unsubscribe'
    url = make_uri(endpoint, api_path)
    params = {'token': args.unsub_event}
    async with session.post(url, params=params) as resp:
        print(resp.status)

async def unsubscribe_promo(session, endpoint, args):
    api_path = '/api/v1/players/notifications/promo/unsubscribe/'
    url = make_uri(endpoint, api_path) + args.unsub_promo
    async with session.post(url) as resp:
        print(resp.status)

async def verify_code(session, endpoint, args):
    api_path = '/api/v1/players/verify/'
    url = make_uri(endpoint, api_path) + args.verify
    headers = createHeaders( args.hostname )
    async with session.get( url, headers=headers ) as resp:
        print(resp.status)

async def get_players_self(session, endpoint, headers, api):
    api_path = API_BASE_PATH + api
    url = make_uri(endpoint, api_path)
    async with session.get(url, headers=headers) as resp:
        return await resp.json()

async def update_players_self(session, endpoint, headers, api, json):
    api_path = API_BASE_PATH + api
    url = make_uri(endpoint, api_path)
    async with session.put(url, headers=headers, json=json) as resp:
        return await resp.json()

async def loginForAuthCode(session, endpoint, args):
    """
    Make OAuth login, return JSON with authCode
    """
    api_path = '/api/v1/oauth/login'
    url = make_uri(endpoint, api_path)
    loginRequest = createLoginRequest(endpoint, args)
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

def createLoginRequest(endpoint, args):
    request = { 'siteId': CA_SITE_CONSTANTS.get('SITE_ID') }

    if endpoint.get('hostname').count( 'mobile' ) > 0:
        request['clientId'] = CA_PD_CONSTANTS.get('MOBILE_CLIENT_ID')
    else:
        request['clientId'] = CA_PD_CONSTANTS.get('PWS_CLIENT_ID')

    if args.username and args.chpwd:
        request['resourceOwnerCredentials'] = {
            'USERNAME': args.username, 'PASSWORD': args.chpwd}
    elif args.username and args.password:
        request['resourceOwnerCredentials'] = {
            'USERNAME': args.username, 'PASSWORD': args.password}
    return request

def createArgParser():
    formatter_class = argparse.RawDescriptionHelpFormatter
    description = '''Python 3.7+ PD API client.\n  ENVIRONMENT: ESA_API_KEY default=''' + DEFAULT_ESA_API_KEY

    parser = argparse.ArgumentParser(formatter_class=formatter_class, description=description)
    parser.add_argument('--activate', help='Activate account with token', required=False, type=str)
    parser.add_argument('--api', help='Names: ' + ','.join(ALL_API_NAMES), type=str)
    parser.add_argument('--available', help='Is username available', type=str)
    parser.add_argument('-c', '--count', help='Repeat count times', type=int, default=1)
    parser.add_argument('--chpwd', help='Change password, --newpwd <NEWPWD>', required=False, type=str)
    parser.add_argument('--hostname', help='Hostname', required=True, type=str)
    parser.add_argument('--forgot', help='Forgot password', type=str)
    parser.add_argument('--lock', help='Lock/suspend account', required=False, action='store_true')
    parser.add_argument('--login', help='Login with username, password, get session token', required=False, action='store_true')
    parser.add_argument('--logout', help='Logout with session token', required=False, type=str)
    parser.add_argument('--unlock', help='Unlock/preactive account', required=False, action='store_true')
    parser.add_argument('-o', '--oauth', help='OAuth session token', required=False, type=str)
    parser.add_argument('--newpwd', help='New password used with chpwd, resetpwd', required=False, type=str )
    parser.add_argument('-p', '--password', help='Password', required=False, default='Password1', type=str)
    parser.add_argument('-q', '--quiet', help='Shhhh', action='store_true')
    parser.add_argument('--reg', help='Register new user', required=False, type=str)
    parser.add_argument('--resetpwd', help='Reset password using <onetimeToken>, --newpwd <NEWPWD>', required=False, type=str)
    parser.add_argument('--resend', help='Resend activation mail', required=False, action='store_true')
    parser.add_argument('-u', '--username', help='Username', required=False, type=str)
    parser.add_argument('--update', help='Update an API from filename or "stdin"', required=False, type=str)
    parser.add_argument('--unsub_event', help='Unsubscribe from a host-event email', required=False, type=str)
    parser.add_argument('--unsub_promo', help='Unsubscribe from promotional email', required=False, type=str)
    parser.add_argument('--verify', help='Verify code', required=False, type=str)
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

        if args.available:
            resp = await is_available(clientSession, endpoint, args)
            print(resp)
            exit_value = 0
            exit(exit_value)
        elif args.activate:
            await activate_account(clientSession, endpoint, args)
            exit_value = 0
            exit(exit_value)
        elif args.forgot:
            await forgotten_password(clientSession, endpoint, args)
            exit_value = 0
            exit(exit_value)
        elif args.logout:
            outh_token = args.logout
            headers['Authorization'] = 'OAuth ' + outh_token
            await logout(clientSession, endpoint, headers, outh_token)
            exit_value = 0
            exit(exit_value)
        elif args.resetpwd:
            await reset_password(clientSession, endpoint, args)
            exit_value = 0
            exit(exit_value)
        elif args.unsub_event:
            await unsubscribe_event(clientSession, endpoint, args)
            exit_value = 0
            exit(exit_value)
        elif args.unsub_promo:
            await unsubscribe_promo(clientSession, endpoint, args)
            exit_value = 0
            exit(exit_value)
        elif args.verify:
            await verify_code(clientSession, endpoint, args)
            exit_value = 0
            exit(exit_value)

        # Login, get token set headers['Authorization']:
        if args.username or args.password or args.chpwd or args.oauth:

            resp_dict = {}
            oauth_token = None

            api_list = []
            if args.reg == None:
                api_list = validateCliApiList(parser)

            if args.username and args.password:

                try:
                   resp_dict = await loginForAuthCode(clientSession, endpoint, args)
                except Exception as e:
                    print(e, file=sys.stderr)
                    exit(exit_value)

                if len(resp_dict) == 3 and resp_dict.get('code') == 'NOT_AUTHENTICATED':
                    print('401: NOT_AUTHENTICATED', file=sys.stderr)
                    exit(exit_value)

                if len(resp_dict) == 1 and resp_dict[0].get('authCode') != None:
                    authCode = resp_dict[0].get('authCode')
                    loginRequest = createLoginRequest(endpoint, args)

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

            if args.api != None and args.update == None:
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
            elif args.api != None and args.update != None:
                json_payload = ''
                if args.update == 'stdin':
                    json_payload = json.load(sys.stdin)
                else:
                    with open(args.update) as f:
                        json_payload = json.load(f)

                response = await update_players_self(clientSession, endpoint, headers, args.api, json_payload)
                print(json.dumps(response, indent=4))
                exit_value = 0
            elif args.username and args.chpwd:
                response = await change_password(clientSession, endpoint, headers, args)
            elif args.lock:
                response = await lock_service(clientSession, endpoint, headers, True)
            elif args.unlock:
                response = await lock_service(clientSession, endpoint, headers, False)
            elif args.login:
                response = await loginForAuthCode(clientSession, endpoint, args)
                authCode = response[0].get('authCode')
                loginRequest = createLoginRequest(endpoint, args)
                response = await getOAuthTokens(clientSession, endpoint, authCode, loginRequest)
                oauth_token = None
                if endpoint.get('hostname').count('mobile') > 0:
                    oauth_token = response[0].get('token')
                else:
                    oauth_token = response[1].get('token')
                print(oauth_token)
            elif args.resend:
                response = await resend_activation_mail(clientSession, endpoint, headers)

    exit(exit_value)

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
    loop.run_until_complete(asyncio.sleep(0.250))
    loop.close()
