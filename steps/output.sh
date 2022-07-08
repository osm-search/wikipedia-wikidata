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
     psql --quiet $DATABASE_NAME
}


echo "====================================================================="
echo "Create output"
echo "====================================================================="

echo "Create wikipedia_article_slim table (remove rows that don't have wikidata title)"
# Remove rows that don't have a title. For redirect only row

echo "DROP TABLE IF EXISTS wikipedia_article_slim;" | psqlcmd
echo "CREATE TABLE wikipedia_article_slim
      AS
      SELECT * FROM wikipedia_article
      WHERE wd_page_title IS NOT NULL
      ;" | psqlcmd

# 5 minutes
# 9.2m rows
echo "Create wikipedia_redirect_slim table (remove rows that don't point to titles in wikidata_article)"

echo "DROP TABLE IF EXISTS wikipedia_redirect_slim;" | psqlcmd
echo "CREATE TABLE wikipedia_redirect_slim
      AS
      SELECT wikipedia_redirect.*
      FROM wikipedia_redirect
      RIGHT OUTER JOIN wikipedia_article
                   ON (wikipedia_redirect.language = wikipedia_article.language
                       AND
                       wikipedia_redirect.to_title = wikipedia_article.title)
      ;" | psqlcmd

# 13m rows


echo "Create wikipedia_importance.sql.gz"

pg_dump -d $DATABASE_NAME -t wikipedia_article_slim -t wikipedia_redirect_slim | \
        grep -v '^SET ' | \
        grep -v 'SELECT ' | \
        grep -v '\-\- ' | \
        sed 's/public.wikipedia_article_slim/wikipedia_article/' | \
        sed 's/public.wikipedia_redirect_slim/wikipedia_redirect/' | \
        gzip -9 > "$OUTPUT_PATH/wikipedia_importance.sql.gz"

echo "Create wikipedia_article.csv.gz"


echo "COPY wikipedia_article_slim
      TO '$OUTPUT_PATH_ABS/wikipedia_article.csv'
      CSV
      DELIMITER ','
      HEADER;" | psqlcmd

gzip -9 "$OUTPUT_PATH_ABS/wikipedia_article.csv"


echo "Create wikipedia_redirect.csv.gz"

echo "COPY wikipedia_redirect_slim
      TO '$OUTPUT_PATH_ABS/wikipedia_redirect.csv'
      CSV
      DELIMITER ','
      HEADER;" | psqlcmd

gzip -9 "$OUTPUT_PATH_ABS/wikipedia_redirect.csv"


du -h $OUTPUT_PATH/*
# 324M  output/wikipedia_article.csv.gz
# 118M  output/wikipedia_redirect.csv.gz