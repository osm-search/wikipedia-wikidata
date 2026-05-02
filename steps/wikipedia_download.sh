#!/bin/bash

echo "====================================================================="
echo "Download individual wikipedia language tables dumps"
echo "====================================================================="

# set defaults
: ${BUILDID:=latest}
# Languages as comma-separated string, e.g. 'en,fr,de'
: ${LANGUAGES:=bar,cy}
LANGUAGES_ARRAY=($(echo $LANGUAGES | tr ',' ' '))
# List of mirrors https://dumps.wikimedia.org/mirrors.html
# Download using main dumps.wikimedia.org: 150 minutes, mirror: 40 minutes
: ${WIKIMEDIA_HOST:=wikidata.aerotechnet.com}
# See list on https://wikidata.aerotechnet.com/enwiki/
: ${WIKIPEDIA_DATE:=20220620}

DOWNLOADED_PATH="$BUILDID/downloaded/wikipedia"

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
    du -h "$2" | cut -f1
}

for WIKILANG in "${LANGUAGES_ARRAY[@]}"; do
    echo "Language: $WIKILANG"

    mkdir -p "$DOWNLOADED_PATH/$WIKILANG"

    # English is the largest
    # 2.1G  downloaded/en/page.sql.gz
    # 6.4G  downloaded/en/pagelinks.sql.gz
    # 492M  downloaded/en/langlinks.sql.gz
    # 992M  downloaded/en/linktarget.sql.gz
    # 160M  downloaded/en/redirect.sql.gz

    # Smaller language Turkish
    #  90M  downloaded/tr/page.sql.gz
    # 255M  downloaded/tr/pagelinks.sql.gz
    # 166M  downloaded/tr/langlinks.sql.gz
    #  62M  downloaded/tr/linktarget.sql.gz
    # 4.2M  downloaded/tr/redirect.sql.gz

    for FN in page.sql.gz pagelinks.sql.gz langlinks.sql.gz linktarget.sql.gz redirect.sql.gz; do

        download https://$WIKIMEDIA_HOST/${WIKILANG}wiki/$WIKIPEDIA_DATE/${WIKILANG}wiki-$WIKIPEDIA_DATE-$FN "$DOWNLOADED_PATH/$WIKILANG/$FN"
        download https://$WIKIMEDIA_HOST/${WIKILANG}wiki/$WIKIPEDIA_DATE/md5sums-${WIKILANG}wiki-$WIKIPEDIA_DATE-$FN.txt "$DOWNLOADED_PATH/$WIKILANG/$FN.md5"

        EXPECTED_MD5=$(cat "$DOWNLOADED_PATH/$WIKILANG/$FN.md5" | cut -d\  -f1)
        CALCULATED_MD5=$(md5sum "$DOWNLOADED_PATH/$WIKILANG/$FN" | cut -d\  -f1)

        if [[ "$EXPECTED_MD5" != "$CALCULATED_MD5" ]]; then
            echo "$FN for language $WIKILANG - md5 checksum doesn't match, download broken"
            exit 1
        fi
    done
done
