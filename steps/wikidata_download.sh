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


DOWNLOADED_PATH="$BUILDID/downloaded/wikidata"
mkdir -p $DOWNLOADED_PATH

download() {
    echo "Downloading $1 > $2"
    if [ -e "$2" ]; then
        echo "file $2 already exists, skipping"
        return
    fi
    header='--header=User-Agent:Osm-search-Bot/1(https://github.com/osm-search/wikipedia-wikidata)'
    wget -O "$2" --quiet $header --no-clobber --tries=3 "$1"
    if [ ! -s "$2" ]; then
        echo "downloaded file $2 is empty, please retry later"
        rm -f "$2"
        exit 1
    fi
}

for FN in geo_tags.sql.gz page.sql.gz wb_items_per_site.sql.gz; do

    # https://wikimedia.bringyour.com/wikidatawiki/20220620/wikidatawiki-20220620-geo_tags.sql.gz
    # https://wikimedia.bringyour.com/wikidatawiki/20220620/md5sums-wikidatawiki-20220620-geo_tags.sql.gz.txt
    download https://$WIKIMEDIA_HOST/wikidatawiki/$WIKIDATA_DATE/wikidatawiki-$WIKIDATA_DATE-$FN             "$DOWNLOADED_PATH/$FN"
    download https://$WIKIMEDIA_HOST/wikidatawiki/$WIKIDATA_DATE/md5sums-wikidatawiki-$WIKIDATA_DATE-$FN.txt "$DOWNLOADED_PATH/$FN.md5"

    EXPECTED_MD5=$(cat "$DOWNLOADED_PATH/$FN.md5"  | cut -d\  -f1)
    CALCULATED_MD5=$(md5sum "$DOWNLOADED_PATH/$FN" | cut -d\  -f1)

    if [[ "$EXPECTED_MD5" != "$CALCULATED_MD5" ]]; then
        echo "$FN - md5 checksum doesn't match, download broken"
        exit 1
    fi

done
du -h $DOWNLOADED_PATH/*

# 114M  downloaded/geo_tags.sql.gz
# 1.7G  downloaded/page.sql.gz
# 1.2G  downloaded/wb_items_per_site.sql.gz
