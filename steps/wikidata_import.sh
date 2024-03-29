#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}

DOWNLOADED_PATH="$BUILDID/downloaded/wikidata"
CONVERTED_PATH="$BUILDID/converted/wikidata"
# postgresql's COPY requires full path
DOWNLOADED_PATH_ABS=$(realpath "$DOWNLOADED_PATH")
CONVERTED_PATH_ABS=$(realpath "$CONVERTED_PATH")

psqlcmd() {
     psql --quiet $DATABASE_NAME |& \
     grep -v 'does not exist, skipping'
}


echo "====================================================================="
echo "Import wikidata tables"
echo "====================================================================="


# -----------------------------------------------------------
echo "Importing geotags from $CONVERTED_PATH_ABS/geo_tags.csv.gz";

echo "DROP TABLE IF EXISTS geo_tags;" | psqlcmd
echo "CREATE TABLE geo_tags (
        gt_page_id    bigint,
        gt_lat        numeric(11,8),
        gt_lon        numeric(11,8)
    );" | psqlcmd


echo "COPY geo_tags (gt_page_id, gt_lat, gt_lon)
    FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/geo_tags.csv.gz'
    CSV
    ;" | psqlcmd



# -----------------------------------------------------------
echo "Importing page from $CONVERTED_PATH_ABS/page.csv.gz";

echo "DROP TABLE IF EXISTS page;" | psqlcmd
echo "CREATE TABLE page (
        page_id            bigint,
        page_title         text
    );" | psqlcmd


echo "COPY page (page_id, page_title)
    FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/page.csv.gz'
    CSV
    ;" | psqlcmd



# -----------------------------------------------------------
echo "Importing wb_items_per_site from $CONVERTED_PATH_ABS/wb_items_per_site.csv.gz";

echo "DROP TABLE IF EXISTS wb_items_per_site;" | psqlcmd
echo "CREATE TABLE wb_items_per_site (
        ips_item_id        integer,
        ips_site_id        text,
        ips_site_page      text
    );" | psqlcmd

echo "COPY wb_items_per_site (ips_item_id, ips_site_id, ips_site_page)
    FROM PROGRAM 'unpigz -c $CONVERTED_PATH_ABS/wb_items_per_site.csv.gz'
    CSV
    ;" | psqlcmd



# -----------------------------------------------------------
echo "Importing wikidata_place_dump from $DOWNLOADED_PATH_ABS/wikidata_place_dump.csv.gz";

echo "DROP TABLE IF EXISTS wikidata_place_dump;" | psqlcmd
echo "CREATE TABLE wikidata_place_dump (
        item        text,
        instance_of text
      );" | psqlcmd

echo "COPY wikidata_place_dump (item, instance_of)
      FROM PROGRAM 'unpigz -c $DOWNLOADED_PATH_ABS/wikidata_place_dump.csv.gz'
      CSV
      ;" | psqlcmd



# -----------------------------------------------------------
echo "Importing wikidata_place_type_levels from $DOWNLOADED_PATH_ABS/wikidata_place_type_levels.csv";

echo "DROP TABLE IF EXISTS wikidata_place_type_levels;" | psqlcmd
echo "CREATE TABLE wikidata_place_type_levels (
        place_type    text,
        level         integer
      );" | psqlcmd

echo "COPY wikidata_place_type_levels (place_type, level)
      FROM '$DOWNLOADED_PATH_ABS/wikidata_place_type_levels.csv'
      CSV
      HEADER
      ;" | psqlcmd

