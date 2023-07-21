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

def get_languages():
    with open('config/languages.txt', 'r') as file:
        languages = file.readlines()
        languages = map(lambda line: line.strip('\n'), languages)
        languages = filter(lambda line: not line.startswith('#'), languages )
    return languages

# TODO: this ignores the environment variable that might be a subset
languages_set = set(get_languages())
if 'LANGUAGES' in os.environ:
    languages_set = set(os.environ['LANGUAGES'].split(','))

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
