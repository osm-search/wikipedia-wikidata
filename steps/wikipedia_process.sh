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

for WIKILANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "INSERT INTO wikipedia_redirect_full
          SELECT '${WIKILANG}',
                 page_title,
                 rd_title
          FROM ${WIKILANG}redirect
          JOIN ${WIKILANG}page ON (rd_from = page_id)
          ;" | psqlcmd
done





echo "====================================================================="
echo "Process language tables and associated pagelink counts"
echo "====================================================================="

echo "set othercounts"
# Creating indexes on title, ll_title didn't have any positive effect on
# query performance and added another 1 hour and 35GB of data.
# echo "CREATE INDEX idx_${WIKILANG}langlinks ON ${WIKILANG}langlinks (ll_lang, ll_title);" | psqlcmd
# echo "CREATE INDEX idx_${WIKILANG}langlinks2 ON ${WIKILANG}langlinks (ll_title);" | psqlcmd
# echo "CREATE INDEX idx_${WIKILANG}page ON ${WIKILANG}page (page_id);" | psqlcmd
# echo "CREATE INDEX idx_${WIKILANG}page2 ON ${WIKILANG}page (page_title);" | psqlcmd
for WIKILANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "Language: $WIKILANG"

    for OTHERLANG in "${LANGUAGES_ARRAY[@]}"
    do
        echo "UPDATE ${WIKILANG}pagelinks
              SET othercount = othercount + x.count
              FROM (
                SELECT ${WIKILANG}page.page_title AS title,
                       ${OTHERLANG}pagelinks.langcount AS count
                FROM ${WIKILANG}langlinks
                JOIN ${WIKILANG}page ON (ll_from = page_id)
                JOIN ${OTHERLANG}pagelinks ON (ll_lang = '${OTHERLANG}' AND ll_title = pl_title)
              ) AS x
              WHERE x.title = ${WIKILANG}pagelinks.pl_title
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

for WIKILANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "INSERT INTO wikipedia_article_full
          SELECT '${WIKILANG}',
                 pl_title,
                 langcount,
                 othercount,
                 langcount + othercount
          FROM ${WIKILANG}pagelinks
          ;" | psqlcmd
done


echo "done"


