#!/usr/bin/env python3

'''
Input from STDIN
# MySQL schema inside the sql.gz file:
#
# CREATE TABLE `page` (
#   `page_id`            int(10) unsigned    NOT NULL AUTO_INCREMENT,
#   `page_namespace`     int(11)             NOT NULL,
#   `page_title`         varbinary(255)      NOT NULL,
#   `page_restrictions`  tinyblob                     DEFAULT NULL,
#   `page_is_redirect`   tinyint(3) unsigned NOT NULL DEFAULT 0,
#   `page_is_new`        tinyint(3) unsigned NOT NULL DEFAULT 0,
#   `page_random`        double unsigned     NOT NULL,
#   `page_touched`       binary(14)          NOT NULL,
#   `page_links_updated` varbinary(14)                DEFAULT NULL,
#   `page_latest`        int(10) unsigned    NOT NULL,
#   `page_len`           int(10) unsigned    NOT NULL,
#   `page_content_model` varbinary(32)                DEFAULT NULL,
#   `page_lang`          varbinary(35)                DEFAULT NULL,

# page_lang isn't interesting, 'NULL' 99.999% of the time

Output to STDOUT: page_id, page_title
'''

import sys
import csv

reader = csv.reader(sys.stdin)

for row in reader:
    # page_namespace: 0 are articles (99% of the input lines)
    if (row[1] != '0'):
        continue

    # page_title are actually ids. Some are special pages, not articles
    if (row[2][0] != 'Q'):
        continue

    print(row[0] + ',' + row[2])
