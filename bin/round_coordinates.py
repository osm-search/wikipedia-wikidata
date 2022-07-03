#!/usr/bin/env python3

'''
'''

import sys
import csv

reader = csv.DictReader(sys.stdin, fieldnames=['page_id', 'lat', 'lon'])

for row in reader:
    lat = float(row['lat'])
    lon = float(row['lon'])

    if (row['lat'] == 0 and row['lon'] == 0):
        print('skipping 0,0', file=sys.stderr)
        continue

    if (lat < -90 or lat > 90 or lon < -180 or lon > 180):
        print('skipping out of bounds', file=sys.stderr)
        # print(lat, file=sys.stderr)
        # print(lon, file=sys.stderr)
        continue

    lat = round(lat, 5)
    lon = round(lon, 5)

    print(row['page_id'] + ',' + str(lat) + ',' + str(lon))
