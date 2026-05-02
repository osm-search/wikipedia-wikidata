#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}
: ${LANGUAGES:=bar,cy}
LANGUAGES_ARRAY=($(echo $LANGUAGES | tr ',' ' '))

CONVERTED_PATH="$BUILDID/converted/wikipedia"
# postgresql's COPY requires full path
CONVERTED_PATH_ABS=$(realpath "$CONVERTED_PATH")

psqlcmd() {
     psql --quiet $DATABASE_NAME |& \
     grep -v 'does not exist, skipping'
}

echo "====================================================================="
echo "Import wikipedia CSV tables"
echo "====================================================================="

for WIKILANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "$WIKILANG"

    # -----------------------------------------------------------
    echo "* ${WIKILANG}page from $CONVERTED_PATH_ABS/$WIKILANG/pages.csv.gz";

    echo "DROP TABLE IF EXISTS ${WIKILANG}page;" | psqlcmd
    echo "CREATE TABLE ${WIKILANG}page (
            page_id            integer,
            page_title         text
        );" | psqlcmd


    echo "COPY ${WIKILANG}page (page_id, page_title)
        FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/$WIKILANG/pages.csv.gz'
        CSV
        ;" | psqlcmd



    # -----------------------------------------------------------
    echo "* ${WIKILANG}pagelinks from $CONVERTED_PATH_ABS/$WIKILANG/pagelinks.csv.gz";

    echo "DROP TABLE IF EXISTS ${WIKILANG}pagelinks;" | psqlcmd
    echo "CREATE TABLE ${WIKILANG}pagelinks (
            pl_title          text,
            langcount         integer,
            othercount        integer DEFAULT 0
        );" | psqlcmd

    echo "COPY ${WIKILANG}pagelinks (pl_title, langcount)
        FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/$WIKILANG/pagelinks.csv.gz'
        CSV
        ;" | psqlcmd


    # -----------------------------------------------------------
    echo "* ${WIKILANG}langlinks from $CONVERTED_PATH_ABS/$WIKILANG/langlinks.csv.gz";

    echo "DROP TABLE IF EXISTS ${WIKILANG}langlinks;" | psqlcmd
    echo "CREATE TABLE ${WIKILANG}langlinks (
            ll_from    integer,
            ll_lang    text,
            ll_title   text
        );" | psqlcmd

    echo "COPY ${WIKILANG}langlinks (ll_title, ll_from, ll_lang)
        FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/$WIKILANG/langlinks.csv.gz'
        CSV
        ;" | psqlcmd


    # -----------------------------------------------------------
    echo "* ${WIKILANG}redirect from $CONVERTED_PATH_ABS/$WIKILANG/redirects.csv.gz";

    echo "DROP TABLE IF EXISTS ${WIKILANG}redirect;" | psqlcmd
    echo "CREATE TABLE ${WIKILANG}redirect (
            rd_from    integer,
            rd_title   text
        );" | psqlcmd

    echo "COPY ${WIKILANG}redirect (rd_from, rd_title)
        FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/$WIKILANG/redirect.csv.gz'
        CSV
        ;" | psqlcmd

done