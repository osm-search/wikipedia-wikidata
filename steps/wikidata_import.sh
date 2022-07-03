#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}

DOWNLOADED_PATH="$BUILDID/downloaded/wikidata"
# postgresql's COPY requires full path
DOWNLOADED_PATH_ABS=$(realpath "$DOWNLOADED_PATH")

psqlcmd() {
     psql --quiet $DATABASE_NAME
}

mysql2pgsqlcmd() {
     ./bin/mysql2pgsql.perl /dev/stdin /dev/stdout
}




echo "====================================================================="
echo "Import wikidata dump tables"
echo "====================================================================="

echo "Importing geo_tags"
gzip -dc "$DOWNLOADED_PATH/geo_tags.sql.gz"          | mysql2pgsqlcmd | psqlcmd

echo "Importing page"
gzip -dc "$DOWNLOADED_PATH/page.sql.gz"              | mysql2pgsqlcmd | psqlcmd

echo "Importing wb_items_per_site"
gzip -dc "$DOWNLOADED_PATH/wb_items_per_site.sql.gz" | mysql2pgsqlcmd | psqlcmd





echo "====================================================================="
echo "Import wikidata places"
echo "====================================================================="

echo "CREATE TABLE wikidata_place_dump (
        item        text,
        instance_of text
      );"  | psqlcmd

echo "COPY wikidata_place_dump (item, instance_of)
      FROM '$DOWNLOADED_PATH_ABS/wikidata_place_dump.csv'
      DELIMITER ','
      CSV
      ;"  | psqlcmd

echo "CREATE TABLE wikidata_place_type_levels (
        place_type text,
        level      integer
      );" | psqlcmd

echo "COPY wikidata_place_type_levels (place_type, level)
      FROM '$DOWNLOADED_PATH_ABS/wikidata_place_type_levels.csv'
      DELIMITER ','
      CSV
      HEADER
      ;" | psqlcmd

