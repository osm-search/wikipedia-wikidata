#!/bin/bash

echo "====================================================================="
echo "Download wikidata dump tables"
echo "====================================================================="

# set defaults
: ${BUILDID:=latest}
# List of mirrors https://dumps.wikimedia.org/mirrors.html
# Download using main dumps.wikimedia.org: 60 minutes, mirror: 20 minutes
: ${WIKIMEDIA_HOST:=wikidata.aerotechnet.com}
# See list on https://wikidata.aerotechnet.com/wikidatawiki/
: ${WIKIDATA_DATE:=20220701}
# An empty download usually means the mirror has not synced that file yet.
# Retry a few times before giving up.
: ${DOWNLOAD_MAX_ATTEMPTS:=5}
: ${DOWNLOAD_RETRY_WAIT:=3600} # 1 hour, to give the mirror time to sync
# Sent on every request; keep in sync with steps/latest_available_data.sh
USER_AGENT='github/osm-search/wikipedia-wikidata'

DOWNLOADED_PATH="$BUILDID/downloaded/wikidata"
mkdir -p $DOWNLOADED_PATH

download() {
    echo "Downloading $1 > $2"
    if [ -e "$2" ]; then
        echo "file $2 already exists, skipping"
        return
    fi
    header="--header=User-Agent:$USER_AGENT"

    for attempt in $(seq 1 "$DOWNLOAD_MAX_ATTEMPTS"); do
        wget -O "$2" --quiet $header --no-clobber --tries=3 "$1"
        if [ -s "$2" ]; then
            du -h "$2" | cut -f1
            return
        fi
        echo "downloaded file $2 is empty (attempt $attempt/$DOWNLOAD_MAX_ATTEMPTS)"
        rm -f "$2"
        if [ "$attempt" -lt "$DOWNLOAD_MAX_ATTEMPTS" ]; then
            echo "mirror may not have synced this file yet, retrying in ${DOWNLOAD_RETRY_WAIT}s ..."
            sleep "$DOWNLOAD_RETRY_WAIT"
        fi
    done

    echo "downloaded file $2 is still empty after $DOWNLOAD_MAX_ATTEMPTS attempts, giving up"
    exit 1
}

for FN in geo_tags.sql.gz page.sql.gz wb_items_per_site.sql.gz; do

    # https://wikidata.aerotechnet.com/wikidatawiki/20250501/wikidatawiki-20250501-geo_tags.sql.gz
    # https://wikidata.aerotechnet.com/wikidatawiki/20250501/md5sums-wikidatawiki-20250501-geo_tags.sql.gz.txt
    download https://$WIKIMEDIA_HOST/wikidatawiki/$WIKIDATA_DATE/wikidatawiki-$WIKIDATA_DATE-$FN "$DOWNLOADED_PATH/$FN"
    download https://$WIKIMEDIA_HOST/wikidatawiki/$WIKIDATA_DATE/md5sums-wikidatawiki-$WIKIDATA_DATE-$FN.txt "$DOWNLOADED_PATH/$FN.md5"

    EXPECTED_MD5=$(cat "$DOWNLOADED_PATH/$FN.md5" | cut -d\  -f1)
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
