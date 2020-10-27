#  #   !/usr/bin/env python

# -*- coding: utf-8 -*-
"""
This Python 3.7 script:

Author: Pete Jansz, 2020
"""

import argparse
import io
import json
import os
import sys

json_payload = None

# if args.update == 'stdin':
#     json_payload = json.load(sys.stdin)
# else:

def createArgParser():
    parser = argparse.ArgumentParser(description='List, enable Host-event notifications JSON')
    parser.add_argument('--file', help='PD notifications-preferences JSON file', required=False, type=str)
    parser.add_argument('--enable', help='Enable all host-event notifications, update file',
                        required=False, action='store_true')
    return parser

def list_prefs(data):
    HEADINGS = 'Event_Name'
    print('EVENT_NAME'.ljust(33, ' '), 'ENABLED')

    for item in data:
        email_channel = item['channels']['EMAIL']
        event_name = str(item['id'])
        enabled = str(email_channel['enabled']).lower()
        print(event_name.ljust(33, ' '), enabled)

def enable_all(data):
    for item in data:
        email_channel = item['channels']['EMAIL']
        email_channel['enabled'] = True
    return data

def load_json(filename):
    with open(filename) as f:
        data = json.load(f)
    return data

def write_data(data, filename):
    with open(filename, 'w') as outfile:
        json.dump(data, outfile, indent=2)

def main():
    exit_value = 1
    parser = createArgParser()
    args = parser.parse_args()

    # if args.update == 'stdin':
    #     json_payload = json.load(sys.stdin)
    # else:

    if not args.file:
        parser.print_help()
        exit(exit_value)

    data = load_json(args.file)

    if args.enable:
        enable_all(data)
        write_data(data, args.file)

    list_prefs(data)

    exit_value = 0
    sys.exit(exit_value)

if __name__ == "__main__":
    main()
