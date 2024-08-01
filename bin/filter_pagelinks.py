#!/usr/bin/env python3

'''
Input from STDIN
    # CREATE TABLE `pagelinks` (
    #   `pl_from`            int(8) unsigned     NOT NULL DEFAULT 0,
    #   `pl_namespace`       int(11)             NOT NULL DEFAULT 0,
    #   `pl_target_id`       bigint(20) unsigned NOT NULL,

Output to STDOUT: pl_title, count
'''

import sys
import csv
import gzip

if len(sys.argv) < 2:
    print("Usage: filter_pagelinks.py linktarget.csv.gz")
    exit(1)

linktarget_filename = sys.argv[1]
linktarget_id_to_title = dict()

with gzip.open(linktarget_filename, 'rt') as gzfile:
    reader = csv.reader(gzfile)
    for row in reader:
        linktarget_id_to_title[row[0]] = row[1]

reader = csv.reader(sys.stdin)
writer = csv.writer(sys.stdout, dialect='unix', quoting=csv.QUOTE_MINIMAL)

counts = {}
for row in reader:
    # pl_namespace: 0 are articles
    if (row[1] != '0'):
        continue

    title = linktarget_id_to_title.get(row[2])
    if title is None:
        continue

    if title not in counts:
        counts[title] = 1
    else:
        counts[title] += 1

# for title in sorted(counts.keys()):
for title in counts.keys():
    writer.writerow([title, counts[title]])
