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

# Similar to 'uniq -c' we look if the title repeats and print a count.
# If the file is unsorted then a title might repeat later in the output. For enwiki though
# the simply 'uniq -c' already cuts the output by 90%
prev_title = None
count = 0

for row in reader:
    # pl_namespace: 0 are articles
    if (row[1] != '0'):
        continue

    title = row[2].replace('\r', '')
    if len(title) == 0:
        continue

    if prev_title is not None and prev_title != title:
        writer.writerow([prev_title, count])
        count = 0

    prev_title = title
    count += 1

if prev_title is not None:
    writer.writerow([prev_title, count])
