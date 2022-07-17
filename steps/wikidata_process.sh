#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}
# Languages as comma-separated string, e.g. 'en,fr,de'
: ${LANGUAGES:=bar,cy}
LANGUAGES_ARRAY=($(echo $LANGUAGES | tr ',' ' '))

psqlcmd() {
     psql --quiet $DATABASE_NAME |& \
     grep -v 'does not exist, skipping'
}







echo "====================================================================="
echo "Create derived tables"
echo "====================================================================="


echo "DROP TABLE IF EXISTS geo_earth_wikidata;" | psqlcmd
echo "CREATE TABLE geo_earth_wikidata AS
      SELECT DISTINCT geo_tags.gt_page_id,
                      geo_tags.gt_lat,
                      geo_tags.gt_lon,
                      page.page_title
      FROM geo_tags
      LEFT OUTER JOIN page
                   ON (geo_tags.gt_page_id = page.page_id)
      ORDER BY geo_tags.gt_page_id
      ;" | psqlcmd

echo "ALTER TABLE wikidata_place_dump
      ADD COLUMN ont_level integer,
      ADD COLUMN lat numeric(11,8),
      ADD COLUMN lon numeric(11,8)
      ;" | psqlcmd

echo "UPDATE wikidata_place_dump
      SET ont_level = wikidata_place_type_levels.level
      FROM wikidata_place_type_levels
      WHERE wikidata_place_dump.instance_of = wikidata_place_type_levels.place_type
      ;" | psqlcmd


echo "DROP TABLE IF EXISTS wikidata_places;" | psqlcmd
echo "CREATE TABLE wikidata_places
      AS
      SELECT DISTINCT ON (item) item,
                                instance_of,
                                MAX(ont_level) AS ont_level,
                                lat,
                                lon
      FROM wikidata_place_dump
      GROUP BY item,
               instance_of,
               ont_level,
               lat,
               lon
      ORDER BY item
      ;" | psqlcmd

echo "UPDATE wikidata_places
      SET lat = geo_earth_wikidata.gt_lat,
          lon = geo_earth_wikidata.gt_lon
      FROM geo_earth_wikidata
      WHERE wikidata_places.item = geo_earth_wikidata.page_title
      ;" | psqlcmd




echo "====================================================================="
echo "Process language pages"
echo "====================================================================="


echo "DROP TABLE IF EXISTS wikidata_pages;" | psqlcmd
echo "CREATE TABLE wikidata_pages (
        item          text,
        instance_of   text,
        lat           numeric(11,8),
        lon           numeric(11,8),
        wp_page_title text,
        language      text
      );" | psqlcmd

for LANG in "${LANGUAGES_ARRAY[@]}"
do
   echo "DROP TABLE IF EXISTS wikidata_${LANG}_pages;" | psqlcmd
   echo "CREATE TABLE wikidata_${LANG}_pages AS
         SELECT wikidata_places.item,
                wikidata_places.instance_of,
                wikidata_places.lat,
                wikidata_places.lon,
                wb_items_per_site.ips_site_page
         FROM wikidata_places
         LEFT JOIN wb_items_per_site
                ON (CAST (( LTRIM(wikidata_places.item, 'Q')) AS INTEGER) = wb_items_per_site.ips_item_id)
         WHERE ips_site_id = '${LANG}wiki'
         ORDER BY wikidata_places.item
         ;" | psqlcmd

   echo "INSERT INTO wikidata_pages
         SELECT item,
                instance_of,
                lat,
                lon,
                REPLACE(ips_site_page, ' ', '_') as wp_page_title,
                '${LANG}'
         FROM wikidata_${LANG}_pages
         ;" | psqlcmd
done




echo "====================================================================="
echo "Add wikidata to wikipedia_article_full table"
echo "====================================================================="

echo "UPDATE wikipedia_article_full
      SET lat           = wikidata_pages.lat,
          lon           = wikidata_pages.lon,
          wd_page_title = wikidata_pages.item,
          instance_of   = wikidata_pages.instance_of
      FROM wikidata_pages
      WHERE wikipedia_article_full.language = wikidata_pages.language
        AND wikipedia_article_full.title  = wikidata_pages.wp_page_title
      ;" | psqlcmd

# 35 minutes
# 166m rows


