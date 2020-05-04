# Purpose: Decode, parse, webcode ('##MRDGZYLYWXJ') into draw-ticket, barcode (10231000003000095990457111) into instant-ticket.
# Example output:
# {
    # "barcode": 10231000003000095990457111,
    # "gameId": 1023,
    # "packId": 1000003,
    # "ticketId": 0,
    # "virn1": 95990457,
    # "virn2": 1,
    # "checkNumber": 1,
    # "pin": 0
# }
#   {
#     "webcode": "##MRDGZYLYWXJ",
#     "serialNumber": 9198867,
#     "productNumber": 15,
#     "cdc": 915,
#     "date": "1988-07-04"
#   },

# Dependancies:
#   Python 2.6 or 3+
#   CLASSPATH to esa-b2b-translets.jar or /usr/share/java/cas-esa-b2b-translet-4.4.0.1.jar or compiled classes
#       ~/Documents/Projects/igt/esa/b2b/branches/cas-b2b_r4_0_dev_br/cas-esa-b2b-translet/target/classes
#   Java
# Author: Pete Jansz
# Date: 2020-04-30

from abc import abstractmethod, ABCMeta
from subprocess import Popen, PIPE
import re, sys, string, os.path, io, subprocess
from datetime import date, timedelta
import io
import json
from json import JSONEncoder
from optparse import OptionParser

CDC1 = '1986.01.01'
parser = OptionParser()

def convertCdcToDateStr(cdc):
    year, month, day = CDC1.split('.')
    cdc1 = date( int(year), int(month), int(day) )
    delta = timedelta( days=cdc )
    return ( str(cdc1 + delta) )

def decode(webcode):
    '''
    Decode webcode to {productNumber, cdc, serialNumber} and return a DrawTicket.
    '''
    draw_ticket = None
    CLASSNAME = 'cas.gtech.translets.WebcodeDecoder'
    classpath = None

    if os.environ.get('CLASSPATH') and os.environ['CLASSPATH'].count('esa-b2b-translet') != 0:
        classpath = os.environ.get('CLASSPATH')
    else:
        classpath = os.environ['USERPROFILE'] + \
            '/Documents/Projects/igt/esa/b2b/branches/cas-b2b_r4_0_dev_br/cas-esa-b2b-translet/target/classes'

    process_session = Popen(['java', '-cp', classpath, CLASSNAME, webcode], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    if process_session.wait() == 0:

        stdoutStrings, stderrStrings = process_session.communicate()

        if process_session.returncode == 0 and len(stdoutStrings) != 0 and len(stderrStrings) == 0:
            dg_ticket_dict = json.loads(stdoutStrings)
            productNumber = int(dg_ticket_dict['productNumber'])
            cdc = int(dg_ticket_dict['cdc'])
            serialNumber = int(dg_ticket_dict['serialNumber'])
            draw_ticket = DrawTicket(webcode, productNumber, cdc, serialNumber)
        else:
            java_exception = str(stderrStrings)

            if java_exception.count('\\r'):
                java_exception = java_exception.split('\\r')[0].strip()
            else:
                java_exception = java_exception.split('\r')[0].strip()

            raise ValueError(java_exception)
    else:
        raise Exception('Popen java subprocess failed.')

    return draw_ticket

class AbstractTicket(object):
    __metaclass__ = ABCMeta

    @classmethod
    @abstractmethod
    def create_csv_header(cls):
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def to_csv(cls):
        raise NotImplementedError

    @classmethod
    @abstractmethod
    def to_dict(cls):
        raise NotImplementedError

class InstantTicket(AbstractTicket):
    __BARCODE_IG_PDF417_LENGTH = 27

    def __init__(self, barcode):
        super(InstantTicket, self).__init__()

        if barcode.isdigit() and len( barcode ) >= self.__BARCODE_IG_PDF417_LENGTH-1:
            self.__barcode = int(barcode)
            self.__gameId = int(barcode[ 0 : 4 ])
            self.__packId = int(barcode[ 4 : 11 ])
            self.__ticketId = int(barcode[ 11 : 14 ])
            self.__virn1 = int(barcode[ 14 : 23 ])
            self.__checkNumber = int(barcode[23])
            self.__virn2 = self.__checkNumber
            self.__pin = 0
        else:
            raise ValueError('Invalid barcode. Must be all-digits, len >= ' + str(self.__BARCODE_IG_PDF417_LENGTH-1))

        if len( barcode ) == self.__BARCODE_IG_PDF417_LENGTH-1:
            self.__isEnteredFromDevice = 0

    @staticmethod
    def BarcodeMinLength():
        return InstantTicket.__BARCODE_IG_PDF417_LENGTH - 1

    def to_dict(self):
        return {
            'barcode': self.__barcode,
            'gameId': self.__gameId,
            'packId': self.__packId,
            'ticketId': self.__ticketId,
            'virn1': self.__virn1,
            'virn2': self.__virn2,
            'checkNumber': self.__checkNumber,
            'pin': self.__pin
        }

    def create_csv_header(self):
        return 'barcode,gameId,packId,ticketId,virn1,virn2,checkNumber,pin'

    def to_csv(self):
        format = '%s,%s,%s,%s,%s,%s,%s,%s'
        return format % (
            self.__barcode,
            self.__gameId,
            self.__packId,
            self.__ticketId,
            self.__virn1,
            self.__virn2,
            self.__checkNumber,
            self.__pin )

    def __str__(self):
        format = 'barcode=%s, gameId=%s, packId=%s, ticketId=%s, virn1=%s, virn2=%s, checkNumber=%s, pin=%s'
        return format % (
            self.__barcode,
            self.__gameId,
            self.__packId,
            self.__ticketId,
            self.__virn1,
            self.__virn2,
            self.__checkNumber,
            self.__pin )

class DrawTicket(AbstractTicket):
    __WEBCODE_LENGTH = 13

    def __init__(self, webcode, product_number, cdc, serial_number):
        super(DrawTicket, self).__init__()
        self.__webcode = webcode
        self.__productNumber = product_number
        self.__cdc = cdc
        self.__serialNumber = serial_number

    def set_webcode(self, webcode):
        self.__webcode = webcode

    def get_webcode(self):
        return self.__webcode

    webcode = property(get_webcode, set_webcode)

    def set_product_number(self, pn):
        self.__productNumber = pn

    def get_product_number(self):
        return self.__productNumber

    productNumber = property(get_product_number, set_product_number)

    def set_cdc(self, cdc):
        self.__cdc = cdc

    def get_cdc(self):
        return self.__cdc

    cdc = property(get_cdc, set_cdc)

    def set_serial_number(self, serial_number):
        self.__serialNumber = serial_number

    def get_serial_number(self):
        return self.__serialNumber

    serialNumber = property(get_serial_number, set_serial_number)

    @staticmethod
    def WebcodeLength():
        return DrawTicket.__WEBCODE_LENGTH

    def to_dict(self):
        return {
            'webcode': self.webcode,
            'serialNumber': self.serialNumber,
            'productNumber': self.productNumber,
            'cdc': self.cdc,
            'date': convertCdcToDateStr(self.cdc)
        }

    def create_csv_header(self):
        return 'webcode,serialNumber,productNumber,cdc,date'

    def to_csv(self):
        format = '%s,%s,%s,%s,%s'
        return format % (self.webcode, str(self.serialNumber), str(self.productNumber), (str(self.cdc)), convertCdcToDateStr(self.cdc))

    def __str__(self):
        format = 'webcode=%s, serialNumber=%s, productNumber=%s, cdc=%s, date=%s'
        return format % (self.webcode, str(self.serialNumber), str(self.productNumber), (str(self.cdc)), convertCdcToDateStr(self.cdc))

def output_json(tickets):
    list = []
    for ticket in tickets.values():
        list.append(ticket.to_dict())

    print(json.dumps(list, indent=2))

def output_csv(tickets):
    count = 0
    for ticket in tickets.values():
        if count == 0:
            print (ticket.create_csv_header())
            count += 1
        print ( ticket.to_csv() )

def parse_cli_args():
    parser.description='Decode ticket draw webcode (##MRDGZYLYWXJ), barcode (10231000003000095990457111) into human-readable form.'
    parser.add_option('-t', '--tickets', action='append', help='Instant barcode or draw webcode', type='string', dest='tickets')
    parser.add_option('-f', '--format', action='store', help='Format: json, csv', type='string', dest='format', default='json')
    return parser.parse_args()

def present_results(tickets, options):
    if len(tickets.values()) > 0:
        if options.format == 'json':
            output_json(tickets)
        elif options.format == 'csv':
            output_csv(tickets)

def main():
    exit_value = 1
    options, args = parse_cli_args()
    if not options.tickets:
        parser.print_help()
        sys.exit(exit_value)

    try:
        tickets = {}
        draw_ticket_count = 0
        instant_ticket_count = 0

        for ticket in options.tickets:
            if draw_ticket_count and instant_ticket_count:
                raise ValueError('Cannot mix draw, instant tickets.')
            if ticket and ticket.isdigit() and len(ticket) >= InstantTicket.BarcodeMinLength():
                instant_ticket_count += 1
                barcode = ticket
                tickets[barcode] = InstantTicket(barcode)
                exit_value = 0
            elif ticket and len(ticket) == DrawTicket.WebcodeLength():
                webcode = ticket
                draw_ticket_count += 1
                draw_ticket = decode(webcode)
                tickets[draw_ticket.serialNumber] = draw_ticket
                exit_value = 0
            else:
                parser.print_help()

        present_results(tickets, options)

    except Exception as error:
        errtype, value, traceback = sys.exc_info()
        sys.stderr.write(str(value))

    sys.exit(exit_value)

if __name__ == "__main__":
    main()
