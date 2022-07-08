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
        ips_site_page text,
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
           AND LEFT(wikidata_places.item,1) = 'Q'
         ORDER BY wikidata_places.item
         ;" | psqlcmd

   echo "ALTER TABLE wikidata_${LANG}_pages
         ADD COLUMN language text
         ;" | psqlcmd

   echo "UPDATE wikidata_${LANG}_pages
         SET language = '${LANG}'
         ;" | psqlcmd

   echo "INSERT INTO wikidata_pages
         SELECT item,
                instance_of,
                lat,
                lon,
                ips_site_page,
                language
         FROM wikidata_${LANG}_pages
         ;" | psqlcmd
done

echo "ALTER TABLE wikidata_pages
      ADD COLUMN wp_page_title text
      ;" | psqlcmd
echo "UPDATE wikidata_pages
      SET wp_page_title = REPLACE(ips_site_page, ' ', '_')
      ;" | psqlcmd
echo "ALTER TABLE wikidata_pages
      DROP COLUMN ips_site_page
      ;" | psqlcmd




echo "====================================================================="
echo "Add wikidata to wikipedia_article table"
echo "====================================================================="

echo "UPDATE wikipedia_article
      SET lat = wikidata_pages.lat,
          lon = wikidata_pages.lon,
          wd_page_title = wikidata_pages.item,
          instance_of = wikidata_pages.instance_of
      FROM wikidata_pages
      WHERE wikipedia_article.language = wikidata_pages.language
        AND wikipedia_article.title  = wikidata_pages.wp_page_title
      ;" | psqlcmd

# 35 minutes
# 166m rows


