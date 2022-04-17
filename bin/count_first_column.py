#!/usr/bin/env python3

'''
Given an input of
a
a
a
b
b
c
a
a
d
... prints ...
a,3
b,2
c,1
a,2
d,1
'''

import sys

prevline = None
counter = 0
for line in sys.stdin:
    line = line.rstrip()
    if prevline is not None and prevline != line:
        print(prevline + ',' + str(counter))
        counter = 0
    prevline = line
    counter += 1

if prevline:
    print(prevline + ',' + str(counter))
