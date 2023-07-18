#!/usr/bin/env python3

'''
Input from STDIN
# MySQL schema inside the sql.gz file:
#
# CREATE TABLE `geo_tags` (
#   `gt_id`      int(10) unsigned NOT NULL AUTO_INCREMENT,
#   `gt_page_id` int(10) unsigned NOT NULL,
#   `gt_globe`   varbinary(32)    NOT NULL,
#   `gt_primary` tinyint(1)       NOT NULL,
#   `gt_lat`     decimal(11,8)              DEFAULT NULL,
#   `gt_lon`     decimal(11,8)              DEFAULT NULL,
#   `gt_dim`     int(11)                    DEFAULT NULL,
#   `gt_type`    varbinary(32)              DEFAULT NULL,
#   `gt_name`    varbinary(255)             DEFAULT NULL,
#   `gt_country` binary(2)                  DEFAULT NULL,
#   `gt_region`  varbinary(3)               DEFAULT NULL,

Output to STDOUT: gt_page_id, gt_lat, gt_lon
'''

import sys
import csv

reader = csv.DictReader(sys.stdin, fieldnames=[
            'gt_id',
            'gt_page_id',
            'gt_globe',
            'gt_primary',
            'gt_lat',
            'gt_lon',
            'gt_dim',
            'gt_type',
            'gt_name',
            'gt_country',
            'gt_region'
        ])

for row in reader:
    # There are places e.g. on the moon with coordinates
    if (row['gt_globe'] != 'earth'):
        continue

    if (row['gt_primary'] != '1'):
        continue

    lat = float(row['gt_lat'])
    lon = float(row['gt_lon'])

    if (lat == 0 and lon == 0):
        # print('skipping 0,0', file=sys.stderr)
        continue

    if (lat < -90 or lat > 90 or lon < -180 or lon > 180):
        # print('skipping out of bounds', file=sys.stderr)
        # print(lat, file=sys.stderr)
        # print(lon, file=sys.stderr)
        continue

    lat = round(lat, 5)
    lon = round(lon, 5)

    print(row['gt_page_id'] + ',' + str(lat) + ',' + str(lon))
