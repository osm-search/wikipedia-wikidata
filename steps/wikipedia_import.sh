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

for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "Language: $LANG"

    # -----------------------------------------------------------
    echo "Importing ${LANG}page from $CONVERTED_PATH_ABS/$LANG/pages.csv.gz";

    echo "DROP TABLE IF EXISTS ${LANG}page;" | psqlcmd
    echo "CREATE TABLE ${LANG}page (
            page_id            integer,
            page_title         text
        );" | psqlcmd


    echo "COPY ${LANG}page (page_id, page_title)
        FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/$LANG/pages.csv.gz'
        CSV
        ;" | psqlcmd



    # -----------------------------------------------------------
    echo "Importing ${LANG}pagelinks from $CONVERTED_PATH_ABS/$LANG/pagelinks.csv.gz";

    echo "DROP TABLE IF EXISTS ${LANG}pagelinks;" | psqlcmd
    echo "CREATE TABLE ${LANG}pagelinks (
            pl_title          text
        );" | psqlcmd

    echo "COPY ${LANG}pagelinks (pl_title)
        FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/$LANG/pagelinks.csv.gz'
        CSV
        ;" | psqlcmd


    # -----------------------------------------------------------
    echo "Importing ${LANG}langlinks from $CONVERTED_PATH_ABS/$LANG/langlinks.csv.gz";

    echo "DROP TABLE IF EXISTS ${LANG}langlinks;" | psqlcmd
    echo "CREATE TABLE ${LANG}langlinks (
            ll_from    integer,
            ll_lang    text,
            ll_title   text
        );" | psqlcmd

    echo "COPY ${LANG}langlinks (ll_title, ll_from, ll_lang)
        FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/$LANG/langlinks.csv.gz'
        CSV
        ;" | psqlcmd


    # -----------------------------------------------------------
    echo "Importing ${LANG}redirect from $CONVERTED_PATH_ABS/$LANG/redirects.csv.gz";

    echo "DROP TABLE IF EXISTS ${LANG}redirect;" | psqlcmd
    echo "CREATE TABLE ${LANG}redirect (
            rd_from    integer,
            rd_title   text
        );" | psqlcmd

    echo "COPY ${LANG}redirect (rd_from, rd_title)
        FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/$LANG/redirect.csv.gz'
        CSV
        ;" | psqlcmd

done