# -*- coding: utf-8 -*-
"""
Use this Python 3.7 script to mass register new CA PD users.

Author: Pete Jansz, 2020
"""

import argparse
import requests
import json
import datetime
import sys
import time

CA_SITE_CONSTANTS = {'SITE_ID': '35', 'SYSTEM_ID': '8', 'MOBILE_CHANNEL_ID': '3', 'PWS_CHANNEL_ID': '2'}

def jsonDefault(object):
    return object.__dict__

def createArgParser():
    parser = argparse.ArgumentParser(description='Mass register new CA PD users.')
    parser.add_argument(
        '--proto', type=str, help='Protocol', default='https', choices=['http', 'https'], required=False)
    parser.add_argument('--hostname', type=str, help='Hostname', required=True)
    parser.add_argument('--baseusername', type=str,
                        help='Base username. Default=mansir', required=True)
    parser.add_argument('--domain', type=str, default='mailinator.com',
                        help='Domain. Default=mailinator.com', required=False)
    parser.add_argument('--start', type=int, default=1,
                        help='Start number. Default=1, e.g., mansir-0001@mailinator.com', required=False)
    parser.add_argument('--count', type=int, help='Count: How many users to create?', required=True)

    return parser

def create_CaProfile(date_time, username):
    return {
        'acceptedTermsAndConditionsDate': date_time,
        'acceptsEmail': True,
        'acceptsPromotionalEmail': True,
        'acceptTermsAndConditions': True,
        'language': 'EN',
        'termsAndConditionsId': date_time,
        'userName': username
        }

def create_mailing():
    return {
        'type': 'MAILING',
        'address1': '123 Elm St',
        'postalCode': '90057',
        'city': 'SACRAMENTO',
        'state': 'CA',
        'isoCountryCode': 'US'
        }

def create_personal_info(username):
    mailing = create_mailing()
    personalInfo = {
        'firstName': 'MAN',
        'lastName': 'SIR',
        'addresses': { 'MAILING': mailing },
        'phones': { 'HOME': {'type': 'HOME', 'number': '0000000000'} },
        'emails': {'PERSONAL': {'type': 'PERSONAL', 'address': username, 'verified': False}},
        'dateOfBirth': 0,
    }

    return personalInfo

def register_user(url, username):
    current_datetime = int(round(time.time() * 1000))

    payload = {
        'password': 'Password1',
        'personalInfo': create_personal_info( username ),
        'nonpublicPersonalInfo': {'dateOfBirth': 0},
        'caProfile': create_CaProfile(current_datetime, username)
        }

    payload_json_str = str(json.dumps(payload, indent=2))

    headers = {
        'content-type': 'application/json',
        'content-length': str(len(payload_json_str)),
        'x-site-id': CA_SITE_CONSTANTS['SITE_ID'],
        'x-ex-system-id': CA_SITE_CONSTANTS['SYSTEM_ID'],
        'x-channel-id': CA_SITE_CONSTANTS['PWS_CHANNEL_ID']
    }

    response = requests.request(
        'POST', url, headers=headers, data=payload_json_str, timeout=30000)
    return response

def main():
    exit_value = 1
    parser = createArgParser()
    args = parser.parse_args()

    if args.hostname == None:
        parser.print_help()
        exit(exit_value)

    if args.baseusername == None:
        parser.print_help()
        exit(exit_value)

    url = '{}://{}/{}'.format(args.proto, args.hostname, 'api/v2/players')

    count = 0
    if args.start <= args.count:
        count = args.count
    else:
        count = args.count

    for i in range(args.start, args.start + count):
        username = '{}-{:0>4d}@{}'.format(args.baseusername, i, args.domain)
        msg = 'Registering {} @ {}'.format(username, url)
        print(msg, end=' ... ', flush=True)
        response = register_user(url, username)
        status_code = response.status_code

        if (status_code == 200):
            print(status_code)
        else:
            msg = 'status_code={}, response-body={}'.format(status_code, response.text.encode('utf8'))
            print(msg, file=sys.stderr)
            exit_value = 1
            break

    exit(exit_value)

if __name__ == "__main__":
    main()
