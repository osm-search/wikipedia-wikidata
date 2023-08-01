#!/usr/bin/env python3

'''
Input from STDIN
    # CREATE TABLE `pagelinks` (
    #   `pl_from`            int(8) unsigned    NOT NULL DEFAULT 0,
    #   `pl_namespace`       int(11)            NOT NULL DEFAULT 0,
    #   `pl_title`           varbinary(255)     NOT NULL DEFAULT '',
    #   `pl_from_namespace`  int(11)            NOT NULL DEFAULT 0,

Output to STDOUT: pl_title, count
'''

import sys
import csv

reader = csv.reader(sys.stdin)
writer = csv.writer(sys.stdout, dialect='unix', quoting=csv.QUOTE_MINIMAL)

counts = {}
for row in reader:
    # pl_namespace: 0 are articles
    if (row[1] != '0'):
        continue

    title = row[2].replace('\r', '')
    if len(title) == 0:
        continue

    if title not in counts:
        counts[title] = 1
    else:
        counts[title] += 1

# for title in sorted(counts.keys()):
for title in counts.keys():
    writer.writerow([title, counts[title]])
