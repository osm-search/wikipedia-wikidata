#!/bin/bash

# psqlcmd() {
#      psql --quiet wikiprocessingdb |& \
#      grep -v 'does not exist, skipping' |& \
#      grep -v 'violates check constraint' |& \
#      grep -vi 'Failing row contains'
# }

psqlcmd() {
     psql --quiet wikiprocessingdb
}

# languages to process (refer to List of Wikipedias here: https://en.wikipedia.org/wiki/List_of_Wikipedias)
# requires Bash 4.0
readarray -t LANGUAGES < languages.txt

for LANG in "${LANGUAGES[@]}"
do
    echo "Language: $i"

    # -----------------------------------------------------------
    echo "Importing pages.csv.gz";

    echo "CREATE TABLE ${LANG}page2 (
            page_id            integer,
            page_title         text
        );" | psqlcmd


    # copy newtable from program 'zcat /tmp/tp.csv.gz'
    # zcat /tmp/newtable.csv.gz | psql -d dbname -c "copy newtable from stdin;"

    echo "COPY ${LANG}page2 (page_id, page_title)
        FROM PROGRAM 'zcat $PWD/converted/${LANG}/pages.csv.gz'
        DELIMITER ','
        CSV
        ;" | psqlcmd



    # -----------------------------------------------------------
    echo "Importing pagelinks.csv.gz";

    echo "CREATE TABLE ${LANG}pagelinks2 (
            pl_title          text
        );" | psqlcmd

    echo "COPY ${LANG}pagelinks2 (pl_title)
        FROM PROGRAM 'zcat $PWD/converted/${LANG}/pagelinks.csv.gz'
        DELIMITER ','
        CSV
        ;" | psqlcmd


    # -----------------------------------------------------------
    echo "Importing langlinks.csv.gz";

    echo "CREATE TABLE ${LANG}langlinks2 (
            ll_from    integer,
            ll_lang    text,
            ll_title   text
        );" | psqlcmd

    echo "COPY ${LANG}langlinks2 (ll_title, ll_from, ll_lang)
        FROM PROGRAM 'zcat $PWD/converted/${LANG}/langlinks.csv.gz'
        DELIMITER ','
        CSV
        ;" | psqlcmd


    # -----------------------------------------------------------
    echo "Importing redirects.csv.gz";

    echo "CREATE TABLE ${LANG}redirects2 (
            rd_from    integer,
            rd_title   text
        );" | psqlcmd

    echo "COPY ${LANG}redirects2 (rd_from, rd_title)
        FROM PROGRAM 'zcat $PWD/converted/${LANG}/redirects.csv.gz'
        DELIMITER ','
        CSV
        ;" | psqlcmd

done