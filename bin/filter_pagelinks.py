#!/usr/bin/env python3

'''
Input from STDIN
    # CREATE TABLE `pagelinks` (
    #   `pl_from`            int(8) unsigned    NOT NULL DEFAULT 0,
    #   `pl_namespace`       int(11)            NOT NULL DEFAULT 0,
    #   `pl_title`           varbinary(255)     NOT NULL DEFAULT '',
    #   `pl_from_namespace`  int(11)            NOT NULL DEFAULT 0,

Output to STDOUT: only pl_title
'''

import sys
import csv

reader = csv.DictReader(sys.stdin, fieldnames=['pl_from', 'pl_namespace', 'pl_title', 'pl_from_namespace'])
writer = csv.DictWriter(sys.stdout, fieldnames=['title'], dialect='unix', quoting=csv.QUOTE_MINIMAL)

for row in reader:
    # 0 are articles
    if (row['pl_namespace'] != '0'):
        continue

    title = row['pl_title'].replace('\r', '')
    if len(title) == 0:
        continue

    writer.writerow({'title': title})
