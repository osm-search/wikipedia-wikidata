#!/bin/bash

# languages to process (refer to List of Wikipedias here: https://en.wikipedia.org/wiki/List_of_Wikipedias)
# requires Bash 4.0
readarray -t LANGUAGES < languages.txt


echo "====================================================================="
echo "Process language tables and associated pagelink counts"
echo "====================================================================="


for i in "${LANGUAGES[@]}"
do
    echo "Language: $i"

    echo "CREATE TABLE ${i}pagelinkcount
          AS
          SELECT pl_title AS title,
                 COUNT(*) AS count,
                 0::bigint as othercount
          FROM ${i}pagelinks
          WHERE pl_namespace = 0
          GROUP BY pl_title
          ;" | psqlcmd

    echo "INSERT INTO linkcounts
          SELECT '${i}',
                 pl_title,
                 COUNT(*)
          FROM ${i}pagelinks
          WHERE pl_namespace = 0
          GROUP BY pl_title
          ;" | psqlcmd

    echo "INSERT INTO wikipedia_redirect
          SELECT '${i}',
                 page_title,
                 rd_title
          FROM ${i}redirect
          JOIN ${i}page ON (rd_from = page_id)
          WHERE page_namespace = 0
            AND rd_namespace = 0
          ;" | psqlcmd

done


for i in "${LANGUAGES[@]}"
do
    for j in "${LANGUAGES[@]}"
    do
        echo "UPDATE ${i}pagelinkcount
              SET othercount = ${i}pagelinkcount.othercount + x.count
              FROM (
                SELECT page_title AS title,
                       count
                FROM ${i}langlinks
                JOIN ${i}page ON (ll_from = page_id)
                JOIN ${j}pagelinkcount ON (ll_lang = '${j}' AND ll_title = title)
              ) AS x
              WHERE x.title = ${i}pagelinkcount.title
              ;" | psqlcmd
    done

    echo "INSERT INTO wikipedia_article
          SELECT '${i}',
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



