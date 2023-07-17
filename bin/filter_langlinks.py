#!/usr/bin/env python3

'''
Input from STDIN
    # CREATE TABLE `langlinks` (
    #   `ll_from`         int(8) unsigned   NOT NULL DEFAULT 0,
    #   `ll_lang`         varbinary(35)     NOT NULL DEFAULT '',
    #   `ll_title`        varbinary(255)    NOT NULL DEFAULT '',

Output to STDOUT: ll_title, ll_from_page_id, ll_lang
'''

import sys

for line in sys.stdin:
    line = line.rstrip().replace('\r', '')

    columns = line.split(',', 2)

    print(','.join([columns[2], columns[0], columns[1]]))
