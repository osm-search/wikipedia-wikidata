#!/usr/bin/env python3

'''
If langlink has a redirect title (last column), then print the
corresponding (same page_title, first column) rows' pagelinkcount
number

Given input of ...

Humboldt-Universitat_Berlin,pagelinkcount,1
Humboldt-Universitat_zu_Berlin,pagelinkcount,1
Humboldt-Universität_Berlin,pagelinkcount,2
Humboldt-Universität_zu_Berlin,langlink,"Humboldtuniversiteit te Berlijn"
Humboldt-Universität_zu_Berlin,pagelinkcount,7

We know the input is sorted a..z, so 'langlink' will always come before 'pagelinkcount'

... prints ...

Humboldt-Universität_zu_Berlin,7



Liberty_Statue_(Budapest),langlink,Statue de la Liberté (Budapest)
Replicas_of_the_Statue_of_Liberty,langlink,Répliques de la statue de la Liberté
Statue_of_Liberty,langlink,Statue de la Liberté
Statue_of_Liberty,pagelinkcount,6
Statue_of_Liberty_(Mytilene),langlink,Statue de la Liberté (Mytilène)
Statue_of_Liberty_(disambiguation),langlink,Statue de la Liberté (homonymie)
Statue_of_Liberty_National_Monument,langlink,Monument national de la statue de la Liberté
Statue_of_Liberty_National_Monument,pagelinkcount,1
Statue_of_Liberty_play,langlink,Statue de la Liberté (football américain)
The_Statue_of_Liberty,pagelinkcount,1
The_Statue_of_Liberty_(documentaire),pagelinkcount,1
Working_on_the_Statue_of_Liberty,pagelinkcount,18

... prints ...
Statue_of_Liberty,6
Statue_of_Liberty_National_Monument,1
'''

import sys
import re

last_page_title = None
saw_redirect = False
for line in sys.stdin:
    line = line.rstrip()

    # No special CSV parsing. We know the middle column is a known
    # string ('langlink' or 'pagelinkcount'). Left and right can
    # be any title, quoted or not.
    # Titles will have the same quotes in the output.
    result = re.match('^(.+),(langlink|pagelinkcount),(.+)', line)
    page_title = result[1]
    line_type = result[2]
    redirect_title_or_count = result[3]

    if (last_page_title is None or page_title != last_page_title):
        saw_redirect = False

    if line_type == 'langlink':
        saw_redirect = True

    if line_type == 'pagelinkcount':
        if saw_redirect:
            count = redirect_title_or_count
            print(page_title + ',' + count)
        # saw_redirect = False

    last_page_title = page_title
