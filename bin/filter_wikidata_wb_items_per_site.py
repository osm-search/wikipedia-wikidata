#!/usr/bin/env python3

'''
Input from STDIN
# MySQL schema inside the sql.gz file:
#
# CREATE TABLE `wb_items_per_site` (
#   `ips_row_id`    bigint(20) unsigned NOT NULL AUTO_INCREMENT,
#   `ips_item_id`   int(10) unsigned    NOT NULL,
#   `ips_site_id`   varbinary(32)       NOT NULL,
#   `ips_site_page` varbinary(310)      NOT NULL,

Output to STDOUT: item_id, site_id, site_page (title)
'''

import os
import sys
import csv

# Add the parent directory to sys.path
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(parent_dir)

from lib.languages import Languages;

languages_set = set(Languages.get_languages())
# print(languages_set, file=sys.stderr)


reader = csv.reader(sys.stdin)
writer = csv.writer(sys.stdout, dialect='unix', quoting=csv.QUOTE_MINIMAL)

for row in reader:
    # ips_site_page is the title
    title = row[3].replace('\r', '')
    if len(title) == 0:
        continue

    # ips_site_id, e.g. 'enwiki'
    language = row[2].replace('wiki', '')
    if language not in languages_set:
        continue

    writer.writerow([row[1], row[2], title])
