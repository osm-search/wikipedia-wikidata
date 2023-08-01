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

reader = csv.reader(sys.stdin)
writer = csv.writer(sys.stdout, dialect='unix', quoting=csv.QUOTE_MINIMAL)

for row in reader:
    # 0 are articles
    if (row[1] != '0'):
        continue

    title = row[2].replace('\r', '')
    if len(title) == 0:
        continue

    writer.writerow([row[0], title])
