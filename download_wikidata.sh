#!/bin/bash

download() {
     echo "Downloading $1"
     header='--header=User-Agent:Osm-search-Bot/1(https://github.com/osm-search/wikipedia-wikidata)'
     wget --no-clobber "$header" --tries=3 "$1" 
}


echo "====================================================================="
echo "Download wikidata dump tables"
echo "====================================================================="

# 114M  wikidatawiki-latest-geo_tags.sql.gz
# 1.7G  wikidatawiki-latest-page.sql.gz
# 1.2G  wikidatawiki-latest-wb_items_per_site.sql.gz
download https://dumps.wikimedia.org/wikidatawiki/latest/wikidatawiki-latest-geo_tags.sql.gz
download https://dumps.wikimedia.org/wikidatawiki/latest/wikidatawiki-latest-page.sql.gz
download https://dumps.wikimedia.org/wikidatawiki/latest/wikidatawiki-latest-wb_items_per_site.sql.gz
