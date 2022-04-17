#!/usr/bin/env python3

'''
Input CSV mapping file (English wikipedia = 16m lines, 500MB uncompressed)
is <page id>,<page title>
1,title1
2,title2
3,'title three'

Input from STDIN is <link title>,<page id>
link5,3
link6,2
link7,999
link8,1

Output to STDOUT is <link title>,<page title>
link5,'title three'
link6,title2
link8,title1
'''


import sys
import csv
import gzip

mapping_file = gzip.open(sys.argv[1], 'rt')

mapping = {}
mapping_reader = csv.DictReader(mapping_file, fieldnames=['page_id', 'page_title'])
for row in mapping_reader:
    mapping[row['page_id']] = row['page_title']

print('mappings read: ' + str(len(mapping.keys())), file=sys.stderr)

reader = csv.DictReader(sys.stdin, fieldnames=['ll_title', 'page_id'])
writer = csv.DictWriter(sys.stdout, fieldnames=['ll_title', 'page_title'])

count_found = 0
count_not_found = 0

for row in reader:
    page_id = row['page_id']

    if page_id in mapping:
        page_title = mapping[page_id]
        count_found += 1
        writer.writerow({
            'll_title': row['ll_title'],
            'page_title': page_title
        })
    else:
        count_not_found += 1
        # print("no page title for " + page_id + " found", file=sys.stderr)

print(
    str(count_found) + " replaced. No page title for " + str(count_not_found) + " lines, skipped.",
    file=sys.stderr
)
