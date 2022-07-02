#!/bin/bash

echo "====================================================================="
echo "Download wikidata dump tables"
echo "====================================================================="

# set defaults
: ${BUILDID:=latest}
# List of mirrors https://dumps.wikimedia.org/mirrors.html
# Download using main dumps.wikimedia.org: 150 minutes, mirror: 40 minutes
: ${WIKIMEDIA_HOST:=wikimedia.bringyour.com}
# See list on https://wikimedia.bringyour.com/wikidatawiki/
: ${WIKIDATA_DATE:=20220620}


DOWNLOADED_PATH="$BUILDID/downloaded"

download() {
    if [ -e "$2" ]; then
        echo "file $2 already exists, skipping"
        return
    fi
    echo "Downloading $1 > $2"
    header='--header=User-Agent:Osm-search-Bot/1(https://github.com/osm-search/wikipedia-wikidata)'
    wget -O "$2" --quiet $header --no-clobber --tries=3 "$1"
    if [ ! -s "$2" ]; then
        echo "downloaded file $2 is empty, please retry later"
        rm -f "$2"
        exit 1
    fi
}

# 114M  downloaded/geo_tags.sql.gz
# 1.7G  downloaded/page.sql.gz
# 1.2G  downloaded/wb_items_per_site.sql.gz

download https://$WIKIMEDIA_HOST/wikidatawiki/$WIKIDATA_DATE/wikidatawiki-$WIKIDATA_DATE-geo_tags.sql.gz          "$DOWNLOADED_PATH/geo_tags.sql.gz"
download https://$WIKIMEDIA_HOST/wikidatawiki/$WIKIDATA_DATE/wikidatawiki-$WIKIDATA_DATE-page.sql.gz              "$DOWNLOADED_PATH/page.sql.gz"
download https://$WIKIMEDIA_HOST/wikidatawiki/$WIKIDATA_DATE/wikidatawiki-$WIKIDATA_DATE-wb_items_per_site.sql.gz "$DOWNLOADED_PATH/wb_items_per_site.sql.gz"