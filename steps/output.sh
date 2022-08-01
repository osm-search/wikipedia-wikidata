#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}

OUTPUT_PATH="$BUILDID/output"
mkdir -p "$OUTPUT_PATH"
# Postgresql server needs to have write access
chmod 777 "$OUTPUT_PATH"
# postgresql's COPY requires full path
OUTPUT_PATH_ABS=$(realpath "$OUTPUT_PATH")

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
# Remove rows that don't point to titles in wikidata_article)"

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
      (
         (
            SELECT language, title, importance, wd_page_title
            FROM wikipedia_article
         )
         UNION
         (
            SELECT r.language, r.from_title, a.importance, a.wd_page_title
            FROM wikipedia_article a, wikipedia_redirect r
            WHERE a.language = r.language and a.title = r.to_title
         )
      );" | psqlcmd

# ?? rows




# "====================================================================="
echo "Create table indexes"
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
echo "CREATE INDEX wikimedia_importance_title_language_idx
      ON wikimedia_importance
      (title, language)
      ;" | psqlcmd
echo "CREATE INDEX wikimedia_importance_wd_page_title_idx
      ON wikimedia_importance
      (wd_page_title)
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
        pigz -f -9 > "$OUTPUT_PATH/wikipedia_importance.sql.gz"



echo "* wikipedia_article.csv.gz"

rm -f "$OUTPUT_PATH_ABS/wikipedia_article.csv.gz"
echo "COPY wikipedia_article
      TO PROGRAM 'pigz -9 > $OUTPUT_PATH_ABS/wikipedia_article.csv.gz'
      CSV
      HEADER;" | psqlcmd



echo "* wikipedia_redirect.csv.gz"

rm -f "$OUTPUT_PATH_ABS/wikipedia_redirect.csv.gz"
echo "COPY wikipedia_redirect
      TO PROGRAM 'pigz -9 > $OUTPUT_PATH_ABS/wikipedia_redirect.csv.gz'
      CSV
      HEADER;" | psqlcmd



echo "* wikimedia_importance.csv.gz"

rm -f "$OUTPUT_PATH_ABS/wikimedia_importance.csv.gz"
echo "COPY wikimedia_importance
      TO PROGRAM 'pigz -9 > $OUTPUT_PATH_ABS/wikimedia_importance.csv.gz'
      CSV
      HEADER;" | psqlcmd

# postgresql owns the files it dumps via COPY
chown "$USER" $OUTPUT_PATH/*.gz

du -h $OUTPUT_PATH/*
# 220M  wikipedia_article.csv.gz
# 87M   wikipedia_redirect.csv.gz
# 305M  wikipedia_importance.sql.gz
# 87M   wikimedia_importance.csv.gz
