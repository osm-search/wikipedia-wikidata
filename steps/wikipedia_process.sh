#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}
: ${LANGUAGES:=bar,cy}
LANGUAGES_ARRAY=($(echo $LANGUAGES | tr ',' ' '))


psqlcmd() {
     psql --quiet $DATABASE_NAME |& \
     grep -v 'does not exist, skipping'
}


echo "====================================================================="
echo "Create and fill wikipedia_redirect_full"
echo "====================================================================="
echo "DROP TABLE IF EXISTS wikipedia_redirect_full;" | psqlcmd
echo "CREATE TABLE wikipedia_redirect_full (
        language   text,
        from_title text,
        to_title   text
     );" | psqlcmd

for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "INSERT INTO wikipedia_redirect_full
          SELECT '${LANG}',
                 page_title,
                 rd_title
          FROM ${LANG}redirect
          JOIN ${LANG}page ON (rd_from = page_id)
          ;" | psqlcmd
done





echo "====================================================================="
echo "Process language tables and associated pagelink counts"
echo "====================================================================="

echo "set counts"
for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "Language: $LANG"

    echo "DROP TABLE IF EXISTS ${LANG}pagelinkcount;" | psqlcmd
    echo "CREATE TABLE ${LANG}pagelinkcount
          AS
          SELECT pl_title AS title,
                 SUM(count) AS langcount,
                 0::bigint as othercount
          FROM ${LANG}pagelinks
          GROUP BY pl_title
          ;" | psqlcmd
done


echo "add underscores to langlinks.ll_title"
# langlinks table contain titles with spaces, e.g. 'one (two)' while pages and
# pagelinkcount table contain titles with underscore, e.g. 'one_(two)'
for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "UPDATE ${LANG}langlinks SET ll_title = REPLACE(ll_title, ' ', '_')
         ;" | psqlcmd
done

echo "set othercounts"
for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "Language: $LANG"

    for OTHERLANG in "${LANGUAGES_ARRAY[@]}"
    do
        # Creating indexes on title, ll_title didn't have any positive effect on
        # query performance and added another 35GB of data.
        echo "UPDATE ${LANG}pagelinkcount
              SET othercount = othercount + x.count
              FROM (
                SELECT ${LANG}page.page_title AS title,
                       ${OTHERLANG}pagelinkcount.langcount AS count
                FROM ${LANG}langlinks
                JOIN ${LANG}page ON (ll_from = page_id)
                JOIN ${OTHERLANG}pagelinkcount ON (ll_lang = '${OTHERLANG}' AND ll_title = title)
              ) AS x
              WHERE x.title = ${LANG}pagelinkcount.title
              ;" | psqlcmd
    done

done



echo "====================================================================="
echo "Create and fill wikipedia_article_full"
echo "====================================================================="

echo "DROP TABLE IF EXISTS wikipedia_article_full;" | psqlcmd
echo "CREATE TABLE wikipedia_article_full (
        language       text NOT NULL,
        title          text NOT NULL,
        langcount      integer,
        othercount     integer,
        totalcount     integer,
        lat            double  precision,
        lon            double  precision,
        importance     double precision,
        title_en       text,
        wd_page_title  text,
        instance_of    text
      );" | psqlcmd

for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "INSERT INTO wikipedia_article_full
          SELECT '${LANG}',
                 title,
                 langcount,
                 othercount,
                 langcount + othercount
          FROM ${LANG}pagelinkcount
          ;" | psqlcmd
done


echo "done"


