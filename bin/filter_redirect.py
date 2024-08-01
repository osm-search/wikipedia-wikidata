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

Same for linktarget table
    # CREATE TABLE `linktarget` (
    #   `lt_id`          bigint(20) unsigned  NOT NULL AUTO_INCREMENT,
    #   `lt_namespace`   int(11)              NOT NULL,
    #   `lt_title`       varbinary(255)       NOT NULL,
'''

import sys
import csv

reader = csv.reader(sys.stdin)
writer = csv.writer(sys.stdout, dialect='unix', quoting=csv.QUOTE_MINIMAL)

for row in reader:
    # namespace: 0 are articles
    if (row[1] != '0'):
        continue

    title = row[2].replace('\r', '')
    if len(title) == 0:
        continue

    writer.writerow([row[0], title])
