#!/usr/bin/env python3

'''
Given input of ...

123,page,page1
123,redirect,redirect1
456,page,page2
789,redirect,redirect2
18193,page,"Emerson,_Lake_&_Palmer"
18193,redirect,"Emerson,_Lake_and_Palmer"
303700,page,Berliner_Bürger
303700,redirect,Berlin
3037005,page,Democratic_Revolutionary_Party
3037005,redirect,Partido_Revolucionario_Democrático
3037006,page,Win_Bischoff
3037006,redirect,Winfried_Bischoff
3037009,page,Haldensleber_Roland
3303700,page,Grafen_von_Rieneck
3303700,redirect,Rieneck_(Adelsgeschlecht)

We know the input is sorted, so 'page' will always be first

... prints ...

redirect1,page1
"Emerson,_Lake_and_Palmer","Emerson,_Lake_&_Palmer"
Berlin,Berliner_Bürger
Partido_Revolucionario_Democrático,Democratic_Revolutionary_Party
Winfried_Bischoff,Win_Bischoff
Rieneck_(Adelsgeschlecht),Grafen_von_Rieneck
'''

import sys
import re

last_page_title = None
last_page_id = None
for line in sys.stdin:
    line = line.rstrip()

    # No special CSV parsing. We know the first columns are number and
    # a-z. Everything after will be a title which might be quoted or
    # not. And easy enough we just keep that and then it will also be
    # proper quoted in the output
    result = re.match(r'^(\d+),(page|redirect),(.*)', line)
    page_id = int(result[1])
    line_type = result[2]
    title = result[3]
    if not title:
        continue

    if line_type == 'redirect' and last_page_id is not None and page_id == last_page_id:
        redirect_title = title
        print(redirect_title + ',' + last_page_title)

    if line_type == 'page':
        last_page_title = title
        last_page_id = page_id
