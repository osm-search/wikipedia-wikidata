#!/usr/bin/env python3

'''
Input from STDIN
    # CREATE TABLE `page` (
    #   `page_id`            int(8) unsigned     NOT NULL AUTO_INCREMENT,
    #   `page_namespace`     int(11)             NOT NULL DEFAULT 0,
    #   `page_title`         varbinary(255)      NOT NULL DEFAULT '',
    #   `page_restrictions`  tinyblob                     DEFAULT NULL,
    #   `page_is_redirect`   tinyint(1) unsigned NOT NULL DEFAULT 0,
    #   `page_is_new`        tinyint(1) unsigned NOT NULL DEFAULT 0,
    #   `page_random`        double unsigned     NOT NULL DEFAULT 0,
    #   `page_touched`       varbinary(14)       NOT NULL DEFAULT '',
    #   `page_links_updated` varbinary(14)                DEFAULT NULL,
    #   `page_latest`        int(8) unsigned     NOT NULL DEFAULT 0,
    #   `page_len`           int(8) unsigned     NOT NULL DEFAULT 0,
    #   `page_content_model` varbinary(32)                DEFAULT NULL,
    #   `page_lang`          varbinary(35)                DEFAULT NULL,

Output to STDOUT: page_id, page_title
'''

import sys
import csv

reader = csv.DictReader(sys.stdin, fieldnames=[
        'page_id',
        'page_namespace',
        'page_title',
        'page_restrictions',
        'page_is_redirect',
        'page_is_new',
        'page_random',
        'page_touched',
        'page_links_updated',
        'page_latest',
        'page_len',
        'page_content_model',
        'page_lang'
    ])
writer = csv.DictWriter(sys.stdout, fieldnames=['id', 'title'], dialect='unix', quoting=csv.QUOTE_MINIMAL)

for row in reader:
    # 0 are articles
    if (row['page_namespace'] != '0'):
        continue

    title = row['page_title'].replace('\r', '')
    if len(title) == 0:
        continue

    writer.writerow({'id': row['page_id'], 'title': title})
