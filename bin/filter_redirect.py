#!/usr/bin/env python3

'''
Input from STDIN
    # CREATE TABLE `redirect` (
    #   `rd_from`         int(8) unsigned   NOT NULL DEFAULT 0,
    #   `rd_namespace`    int(11)           NOT NULL DEFAULT 0,
    #   `rd_title`        varbinary(255)    NOT NULL DEFAULT '',
    #   `rd_interwiki`    varbinary(32)              DEFAULT NULL,
    #   `rd_fragment`     varbinary(255)             DEFAULT NULL,

Output to STDOUT: rd_from_page_id, rd_title
'''

import sys
import csv

reader = csv.DictReader(sys.stdin, fieldnames=[
        'rd_from',
        'rd_namespace',
        'rd_title',
        'rd_interwiki',
        'rd_fragment'
    ])
writer = csv.DictWriter(sys.stdout, fieldnames=['id', 'title'], dialect='unix', quoting=csv.QUOTE_MINIMAL)

for row in reader:
    # 0 are articles
    if (row['rd_namespace'] != '0'):
        continue

    title = row['rd_title'].replace('\r', '')
    if len(title) == 0:
        continue

    writer.writerow({'id': row['rd_from'], 'title': title})
