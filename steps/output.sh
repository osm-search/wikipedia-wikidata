#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}

OUTPUT_PATH="$BUILDID/output"
mkdir -p "$OUTPUT_PATH"

psqlcmd() {
     psql --quiet $DATABASE_NAME |& \
     grep -v 'does not exist, skipping'
}


echo "====================================================================="
echo "Create output"
echo "====================================================================="


# "====================================================================="
echo "Create tables"
# "====================================================================="


echo "* wikipedia_article (Less rows and columns than wikipedia_article_full)"
# Remove rows that don't have a title. For redirect only row

echo "DROP TABLE IF EXISTS wikipedia_article;" | psqlcmd
echo "CREATE TABLE wikipedia_article
      AS
      SELECT language, title, importance, wd_page_title FROM wikipedia_article_full
      WHERE wd_page_title IS NOT NULL
        AND importance != 0
      ;" | psqlcmd

# 5 minutes
# 9.2m rows

echo "* wikipedia_redirect (Less rows than wikipedia_redirect_full)"
# Remove rows that don't point to titles in wikipedia_article)"

echo "DROP TABLE IF EXISTS wikipedia_redirect;" | psqlcmd
echo "CREATE TABLE wikipedia_redirect
      AS
      SELECT wikipedia_redirect_full.*
      FROM wikipedia_redirect_full
      RIGHT OUTER JOIN wikipedia_article
                   ON (wikipedia_redirect_full.language = wikipedia_article.language
                       AND
                       wikipedia_redirect_full.to_title = wikipedia_article.title)
      ;" | psqlcmd

# 13m rows

echo "* wikimedia_importance"

echo "DROP TABLE IF EXISTS wikimedia_importance;" | psqlcmd
echo "CREATE TABLE wikimedia_importance AS
      SELECT language, 'a' as type, title, importance, wd_page_title as wikidata_id
      FROM wikipedia_article
      ;" | psqlcmd

# Now add the same from redirects, unless (language + title) already exists in wikimedia_importance
echo "WITH from_redirects AS (
          SELECT r.language, 'r' as type, r.from_title as title, a.importance, a.wd_page_title AS wikidata_id
          FROM wikipedia_article a, wikipedia_redirect r
          WHERE a.language = r.language AND a.title = r.to_title
      )
      INSERT INTO wikimedia_importance
      SELECT from_redirects.* FROM from_redirects
      LEFT JOIN wikimedia_importance USING (language, title)
      WHERE wikimedia_importance IS NULL
      ;" | psqlcmd

# Are all language+title unique?
# WITH duplicates AS (
#   SELECT language, title, count(*)
#   FROM wikimedia_importance
#   GROUP BY language, title
#   HAVING count(*) > 1
# )
# SELECT count(*) FROM duplicates;
#  0

# 17m rows




# "====================================================================="
echo "Create indexes"
# "====================================================================="

echo "CREATE INDEX wikipedia_article_title_language_idx
      ON wikipedia_article
      (title, language)
      ;" | psqlcmd
echo "CREATE INDEX wikipedia_article_wd_page_title_idx
      ON wikipedia_article
      (wd_page_title)
      ;" | psqlcmd
echo "CREATE INDEX wikipedia_redirect_language_from_title_idx
      ON wikipedia_redirect
      (language, from_title)
      ;" | psqlcmd




# "====================================================================="
echo "Dump tables"
# "====================================================================="

echo "* wikipedia_importance.sql.gz"

pg_dump -d $DATABASE_NAME --no-owner -t wikipedia_article -t wikipedia_redirect | \
        grep -v '^SET ' | \
        grep -v 'SELECT ' | \
        grep -v '\-\- ' | \
        sed 's/public\.//' | \
        pigz -9 > "$OUTPUT_PATH/wikipedia_importance.sql.gz"


for TABLE in wikipedia_article wikipedia_redirect wikimedia_importance
do
      echo "* $TABLE.csv.gz"

      {
            echo "COPY (SELECT * FROM $TABLE LIMIT 0) TO STDOUT WITH DELIMITER E'\t' CSV HEADER" | \
                  psqlcmd
            echo "COPY $TABLE TO STDOUT" | \
                  psqlcmd | \
                  sort
      } | pigz -9 > "$OUTPUT_PATH/$TABLE.csv.gz"

      # default is 600
      chmod 644 "$OUTPUT_PATH/$TABLE.csv.gz"
done


du -h $OUTPUT_PATH/*
# 220M  wikipedia_article.csv.gz
# 87M   wikipedia_redirect.csv.gz
# 305M  wikipedia_importance.sql.gz
# 87M   wikimedia_importance.csv.gz
