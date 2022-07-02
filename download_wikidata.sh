#!/bin/bash

echo "====================================================================="
echo "Download wikidata dump tables"
echo "====================================================================="

if [[ !$BUILDID ]]; then
    BUILDID=latest
fi

# List of mirrors https://dumps.wikimedia.org/mirrors.html
# Download using main server: 150 minutes, mirror: 40 minutes
# HOST="dumps.wikimedia.org"
HOST="wikimedia.bringyour.com"

# Check https://wikimedia.bringyour.com/wikidatawiki/ which dates
# are available. Actually open the directory to check if the dump
# finished.
DATE='20220701'
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

download https://$HOST/wikidatawiki/$DATE/wikidatawiki-$DATE-geo_tags.sql.gz          "$DOWNLOADED_PATH/geo_tags.sql.gz"
download https://$HOST/wikidatawiki/$DATE/wikidatawiki-$DATE-page.sql.gz              "$DOWNLOADED_PATH/page.sql.gz"
download https://$HOST/wikidatawiki/$DATE/wikidatawiki-$DATE-wb_items_per_site.sql.gz "$DOWNLOADED_PATH/wb_items_per_site.sql.gz"