#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}

OUTPUT_PATH="$BUILDID/output"
mkdir -p "$OUTPUT_PATH"

psqlcmd() {
      psql --quiet $DATABASE_NAME |&
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
echo "Dump table"
# "====================================================================="

# Temporary table for sorting the output by most popular language. Nominatim assigns
# the wikipedia extra tag to the first language it finds during import and English (en)
# makes debugging easier than Arabic (ar).
# Not a temporary table actually because with each psqlcmd call we start a new
# session.
#
#  language |  size
# ----------+---------
#  en       | 3360898
#  de       |  989366
#  fr       |  955523
#  uk       |  920531
#  sv       |  918185

echo "DROP TABLE IF EXISTS top_languages;" | psqlcmd
echo "CREATE TABLE top_languages AS
      SELECT language, COUNT(*) AS size
      FROM wikimedia_importance
      GROUP BY language
      ORDER BY size DESC
      ;" | psqlcmd

echo "* wikimedia_importance.tsv.gz"

{
      # Prints the CSV header row
      # language  type  title importance  wikidata_id
      echo "COPY (SELECT * FROM wikimedia_importance LIMIT 0) TO STDOUT WITH DELIMITER E'\t' CSV HEADER" |
            psqlcmd
      echo "COPY (
                  SELECT w.*
                  FROM wikimedia_importance w
                  JOIN top_languages tl ON w.language = tl.language
                  ORDER BY tl.size DESC, w.type, w.title
            ) TO STDOUT" |
            psqlcmd
} | pigz -9 >"$OUTPUT_PATH/wikimedia_importance.tsv.gz"

# default is 600
chmod 644 "$OUTPUT_PATH/wikimedia_importance.tsv.gz"

du -h $OUTPUT_PATH/*
# 265M  wikimedia_importance.tsv.gz
