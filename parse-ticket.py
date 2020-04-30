#
# Author: Pete Jansz
# Date: 2020-04-30

from subprocess import Popen, PIPE
import re, sys, string, os.path, io, subprocess
from datetime import date
import io
import json
from optparse import OptionParser

parser = OptionParser()

def decode(webcode):
    '''
    Decode webcode to {productNumber, cdc, serialNumber} and return a DrawTicket.
    '''
    draw_ticket = None
    CLASSNAME = 'cas.gtech.translets.WebcodeDecoder'
    classpath = None

    if os.environ.get('CLASSPATH') and os.environ['CLASSPATH'].count('cas-esa-b2b-translet') != 0:
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

class InstantTicket(object):
    __BARCODE_IG_PDF417_LENGTH = 27

    def __init__(self, barcode):
        super(InstantTicket, self).__init__()

        if barcode.isdigit() and len( barcode ) >= self.__BARCODE_IG_PDF417_LENGTH-1:
            self.__barcode = barcode
            self.__gameId = barcode[ 0 : 4 ]
            self.__packId = barcode[ 4 : 11 ]
            self.__ticketId = barcode[ 11 : 14 ]
            self.__virn1 = barcode[ 14 : 23 ]
            self.__checkNumber = barcode[23]
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
            'gameId': self.__gameId,
            'packId': self.__packId,
            'ticketId': self.__ticketId,
            'virn1': self.__virn1,
            'virn2': self.__virn2,
            'checkNumber': self.__checkNumber,
            'pin': self.__pin
        }

    def __str__(self):
        format = 'gameId=%s, packId=%s, ticketId=%s, virn1=%s, virn2=%s, checkNumber=%s, pin=%s'
        return format % ( self.__gameId, self.__packId, self.__ticketId, self.__virn1, self.__virn2, self.__checkNumber, self.__pin )

class DrawTicket(object):
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
            'productNumber': self.productNumber,
            'cdc': self.cdc,
            'serialNumber': self.serialNumber
        }

    def __str__(self):
        format = 'webcode=%s, productNumber=%s, cdc=%s, serialNumber=%s'
        return format % (self.webcode, str(self.productNumber), (str(self.cdc)), str(self.serialNumber))

def parse_cli_args():
    parser.add_option('-t', '--tickets', action='append', help='Instant barcode or draw webcode',
                      dest='tickets')
    return parser.parse_args()

def main():
    exit_value = 1
    options, args = parse_cli_args()
    if not options.tickets:
        parser.print_help()
        sys.exit(exit_value)

    try:
        instant_tickets = {}
        draw_tickets = {}

        for ticket in options.tickets:
            if ticket and ticket.isdigit() and len(ticket) >= InstantTicket.BarcodeMinLength():
                barcode = ticket
                instant_ticket = InstantTicket(barcode)
                instant_tickets[ticket] = instant_ticket.to_dict()
                exit_value = 0
            elif ticket and len(ticket) == DrawTicket.WebcodeLength():
                webcode = ticket
                draw_ticket = decode(webcode)
                draw_tickets[webcode] = draw_ticket.to_dict()
                exit_value = 0
            else:
                parser.print_help()

        # Present results
        if len(instant_tickets.keys()):
            print(json.dumps(instant_tickets, ensure_ascii=True, indent=2))

        if len(draw_tickets.keys()):
            print(json.dumps(draw_tickets, ensure_ascii=True, indent=2))

    except Exception as error:
        errtype, value, traceback = sys.exc_info()
        sys.stderr.write(str(value))

    sys.exit(exit_value)

if __name__ == "__main__":
    main()
