#!/bin/bash

psqlcmd() {
     psql --quiet wikiprocessingdb
}



# languages to process (refer to List of Wikipedias here: https://en.wikipedia.org/wiki/List_of_Wikipedias)
# requires Bash 4.0
readarray -t LANGUAGES < languages.txt







echo "====================================================================="
echo "Create derived tables"
echo "====================================================================="

echo "CREATE TABLE geo_earth_primary AS
      SELECT gt_page_id,
             gt_lat,
             gt_lon
      FROM geo_tags
      WHERE gt_globe = 'earth'
        AND gt_primary = 1
        AND NOT(    gt_lat < -90
                 OR gt_lat > 90
                 OR gt_lon < -180
                 OR gt_lon > 180
                 OR gt_lat=0
                 OR gt_lon=0)
      ;" | psqlcmd

echo "CREATE TABLE geo_earth_wikidata AS
      SELECT DISTINCT geo_earth_primary.gt_page_id,
                      geo_earth_primary.gt_lat,
                      geo_earth_primary.gt_lon,
                      page.page_title,
                      page.page_namespace
      FROM geo_earth_primary
      LEFT OUTER JOIN page
                   ON (geo_earth_primary.gt_page_id = page.page_id)
      ORDER BY geo_earth_primary.gt_page_id
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


echo "CREATE TABLE wikidata_pages (
        item          text,
        instance_of   text,
        lat           numeric(11,8),
        lon           numeric(11,8),
        ips_site_page text,
        language      text
      );" | psqlcmd

for i in "${LANGUAGES[@]}"
do
   echo "CREATE TABLE wikidata_${i}_pages AS
         SELECT wikidata_places.item,
                wikidata_places.instance_of,
                wikidata_places.lat,
                wikidata_places.lon,
                wb_items_per_site.ips_site_page
         FROM wikidata_places
         LEFT JOIN wb_items_per_site
                ON (CAST (( LTRIM(wikidata_places.item, 'Q')) AS INTEGER) = wb_items_per_site.ips_item_id)
         WHERE ips_site_id = '${i}wiki'
           AND LEFT(wikidata_places.item,1) = 'Q'
         ORDER BY wikidata_places.item
         ;" | psqlcmd

   echo "ALTER TABLE wikidata_${i}_pages
         ADD COLUMN language text
         ;" | psqlcmd

   echo "UPDATE wikidata_${i}_pages
         SET language = '${i}'
         ;" | psqlcmd

   echo "INSERT INTO wikidata_pages
         SELECT item,
                instance_of,
                lat,
                lon,
                ips_site_page,
                language
         FROM wikidata_${i}_pages
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

echo "CREATE TABLE wikipedia_article_slim
      AS
      SELECT * FROM wikipedia_article
      WHERE wikidata_id IS NOT NULL
      ;" | psqlcmd

echo "ALTER TABLE wikipedia_article
      RENAME TO wikipedia_article_full
      ;" | psqlcmd

echo "ALTER TABLE wikipedia_article_slim
      RENAME TO wikipedia_article
      ;" | psqlcmd


