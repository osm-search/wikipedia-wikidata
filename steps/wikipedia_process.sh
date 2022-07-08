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
echo "Create wikipedia calculation tables"
echo "====================================================================="

echo "DROP TABLE IF EXISTS linkcounts;" | psqlcmd
echo "CREATE TABLE linkcounts (
        language text,
        title    text,
        count    integer,
        sumcount integer,
        lat      double precision,
        lon      double precision
     );"  | psqlcmd

echo "DROP TABLE IF EXISTS wikipedia_article;" | psqlcmd
echo "CREATE TABLE wikipedia_article (
        language    text NOT NULL,
        title       text NOT NULL,
        langcount   integer,
        othercount  integer,
        totalcount  integer,
        lat double  precision,
        lon double  precision,
        importance  double precision,
        title_en    text,
        osm_type    character(1),
        osm_id      bigint
      );" | psqlcmd

echo "DROP TABLE IF EXISTS wikipedia_redirect;" | psqlcmd
echo "CREATE TABLE wikipedia_redirect (
        language   text,
        from_title text,
        to_title   text
     );" | psqlcmd


echo "====================================================================="
echo "Process language tables and associated pagelink counts"
echo "====================================================================="


for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "Language: $i"

    echo "DROP TABLE IF EXISTS ${LANG}pagelinkcount;" | psqlcmd
    echo "CREATE TABLE ${LANG}pagelinkcount
          AS
          SELECT pl_title AS title,
                 COUNT(*) AS count,
                 0::bigint as othercount
          FROM ${LANG}pagelinks
          WHERE pl_namespace = 0
          GROUP BY pl_title
          ;" | psqlcmd

    echo "INSERT INTO linkcounts
          SELECT '${LANG}',
                 pl_title,
                 COUNT(*)
          FROM ${i}pagelinks
          WHERE pl_namespace = 0
          GROUP BY pl_title
          ;" | psqlcmd

    echo "INSERT INTO wikipedia_redirect
          SELECT '${LANG}',
                 page_title,
                 rd_title
          FROM ${LANG}redirect
          JOIN ${LANG}page ON (rd_from = page_id)
          WHERE page_namespace = 0
            AND rd_namespace = 0
          ;" | psqlcmd

done


for LANG in "${LANGUAGES_ARRAY[@]}"
do
    for OTHERLANG in "${LANGUAGES_ARRAY[@]}"
    do
        echo "UPDATE ${LANG}pagelinkcount
              SET othercount = ${LANG}pagelinkcount.othercount + x.count
              FROM (
                SELECT page_title AS title,
                       count
                FROM ${LANG}langlinks
                JOIN ${LANG}page ON (ll_from = page_id)
                JOIN ${OTHERLANG}pagelinkcount ON (ll_lang = '${OTHERLANG}' AND ll_title = title)
              ) AS x
              WHERE x.title = ${LANG}pagelinkcount.title
              ;" | psqlcmd
    done

    echo "INSERT INTO wikipedia_article
          SELECT '${LANG}',
                 title,
                 count,
                 othercount,
                 count + othercount
          FROM ${i}pagelinkcount
          ;" | psqlcmd
done





echo "====================================================================="
echo "Calculate importance score for each wikipedia page"
echo "====================================================================="

echo "UPDATE wikipedia_article
      SET importance = LOG(totalcount)/LOG((SELECT MAX(totalcount) FROM wikipedia_article))
      ;" | psqlcmd

echo "done"
