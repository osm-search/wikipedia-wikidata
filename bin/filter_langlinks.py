#!/usr/bin/env python3

'''
Input from STDIN
    # CREATE TABLE `langlinks` (
    #   `ll_from`         int(8) unsigned   NOT NULL DEFAULT 0,
    #   `ll_lang`         varbinary(35)     NOT NULL DEFAULT '',
    #   `ll_title`        varbinary(255)    NOT NULL DEFAULT '',

Output to STDOUT: ll_title, ll_from_page_id, ll_lang
'''

import os
import sys

parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(parent_dir)

from lib.languages import Languages;

languages_set = set(Languages.get_languages())


# We don't need CSV parsing here because the first two columns never
# contain commas.
for line in sys.stdin:
    line = line.rstrip().replace('\r', '')

    columns = line.split(',', 2)

    # ll_lang, e.g. 'en'
    language = columns[1]
    if language not in languages_set:
        continue

    # langlinks table contain titles with spaces, e.g. 'one (two)' while pages and
    # pagelinkcount table contain titles with underscore, e.g. 'one_(two)'
    title = columns[2].replace(' ', '_')

    print(','.join([title, columns[0], language]))
