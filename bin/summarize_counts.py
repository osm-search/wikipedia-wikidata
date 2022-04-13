#!/usr/bin/env python3

'''
Similar to count_first_column.py
TODO: merge count_first_column.py and this script. Requires writing
some tests.
'''

Given an input of
a,3
a,2
b,2
c,1
d,1
... prints ...
a,5
b,2
c,1
d,1
'''

import sys
import re

prevvalue = None
counter = 0
for line in sys.stdin:
    line = line.rstrip()

    result = re.match(r'^(.+),(\d+)$', line)
    if result:
        value = result[1]
        count = int(result[2])

        if prevvalue is not None and prevvalue != value:
            print(prevvalue + ',' + str(counter))
            counter = 0
        prevvalue = value
        counter += count
    else:
        print("no regexp match at: " + line, file=sys.stderr)

print(prevvalue + ',' + str(counter))
