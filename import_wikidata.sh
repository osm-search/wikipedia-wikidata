#!/bin/bash

psqlcmd() {
     psql --quiet wikiprocessingdb
}

mysql2pgsqlcmd() {
     ./bin/mysql2pgsql.perl /dev/stdin /dev/stdout
}




echo "====================================================================="
echo "Import wikidata dump tables"
echo "====================================================================="

echo "Importing wikidatawiki-latest-geo_tags"
gzip -dc wikidatawiki-latest-geo_tags.sql.gz          | mysql2pgsqlcmd | psqlcmd

echo "Importing wikidatawiki-latest-page"
gzip -dc wikidatawiki-latest-page.sql.gz              | mysql2pgsqlcmd | psqlcmd

echo "Importing wikidatawiki-latest-wb_items_per_site"
gzip -dc wikidatawiki-latest-wb_items_per_site.sql.gz | mysql2pgsqlcmd | psqlcmd





echo "====================================================================="
echo "Import wikidata places"
echo "====================================================================="

echo "CREATE TABLE wikidata_place_dump (
        item        text,
        instance_of text
      );"  | psqlcmd

echo "COPY wikidata_place_dump (item, instance_of)
      FROM '$PWD/wikidata_place_dump.csv'
      DELIMITER ','
      CSV
      ;"  | psqlcmd

echo "CREATE TABLE wikidata_place_type_levels (
        place_type text,
        level      integer
      );" | psqlcmd

echo "COPY wikidata_place_type_levels (place_type, level)
      FROM '$PWD/wikidata_place_type_levels.csv'
      DELIMITER ','
      CSV
      HEADER
      ;" | psqlcmd

