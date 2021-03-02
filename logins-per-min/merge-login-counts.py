#! /usr/bin/python
# Python 2

# Merge two export del files both of format, 'YYYY-MM-DD,HR,MIN,COUNT', e.g., "2020-01-27",0,0,22
#   adding count into output csv file, format:
#   YYYY-MM-DD, HR, MIN, COUNT
#   2020-01-17, 2, 31, 12
#   2020-01-27, 12, 38, 176
#
# Author: Pete Jansz

from os import chdir
import re, sys, string, os.path, io
from optparse import OptionParser
from datetime import datetime

parser = OptionParser()

CSV_HEADERS = 'YYYY-MM-DD,HR,MIN,COUNT'

def parse_cli_args():
    parser.add_option('--delfile1', action='store', help='Input DEL file 1, default=logins-per-min.del',
                      type='str', dest='delfile1', metavar='FILE', default='logins-per-min.del')
    parser.add_option('--delfile2', action='store', help='Input DEL file 2, default=logins-per-min-archive.del',
                      type='str', dest='delfile2', metavar='FILE', default='logins-per-min-archive.del')
    parser.add_option('--sort_date', action='store_true',
                      help='Sort results by date/time. Default=count', dest='sort_date', default=False)
    parser.add_option('--asc', action='store_false', help='Sort asc. Default=desc', dest='asc', default=True)
    return parser.parse_args()

def load_map( filename ):
    map = {}
    fin = open(filename, 'r')

    for line in fin.readlines():
        if line.find('COUNT') >= 0: # Skip CSV_HEADERS if found
            continue
        line = line.strip().replace('"', '')
        (yyyy_mm_dd, hr, minute, count) = line.strip().split(',')
        key = "{0},{1},{2}".format(yyyy_mm_dd, hr, minute)
        map[key] = int(count)

    fin.close()

    return map

def comparator(p, q):
    __DATETIME_FORMAT = '%Y-%m-%d,%H,%M'
    p = datetime.strptime(p, __DATETIME_FORMAT)
    q = datetime.strptime(q, __DATETIME_FORMAT)

    if p < q:
        return -1
    elif p > q:
        return 1
    else:
        return 0

def write_report(map, options):
    print (CSV_HEADERS)

    if options.sort_date:
        for key in sorted(map.keys(), cmp=comparator, reverse=options.asc):
            outstr = '{0},{1}\n'.format(key, map[key])
            print outstr,
    else:
        for item in sorted(map.items(), key=lambda x: x[1], reverse=options.asc):
            # item is a tuple from sorted(map.items)
            if not options.sort_date:
                outstr = '{0},{1}\n'.format(item[0], item[1])
            print outstr,

# Return a map of the merge of map1, map2
def merge_maps( map1, map2 ):
    merged_results_map = map1.copy()

    # Using map1 as master keyset
    for key in merged_results_map:
        count1 = map1[key]

        if key in map2:
            count2 = map2[key]
            merged_results_map[key] = count1 + count2

    # Using map2 as master keyset
    # Add keys/values to merged where not exist
    for key in map2:
        if key not in merged_results_map:
            count2 = map2[key]
            merged_results_map[key] = count2

    return merged_results_map

def main():
    options, args = parse_cli_args()

    if not options.delfile1 or not options.delfile2:
        parser.print_help()
        exit(1)

    for f in options.delfile1, options.delfile2:
        if not os.path.exists( f ):
            print >>sys.stderr, 'File not found: ' + f
            exit(1)

    map1 = load_map( options.delfile1 )
    map2 = load_map( options.delfile2 )
    merged_results_map = merge_maps( map1, map2 )
    write_report( merged_results_map, options )

if __name__ == "__main__":
    main()
