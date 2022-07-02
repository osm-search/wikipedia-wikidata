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
: ${WIKIMEDIA_HOST:=wikimedia.bringyour.com}
# See list on https://wikimedia.bringyour.com/wikidatawiki/
: ${WIKIPEDIA_DATE:=20220620}


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

for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "Language: $LANG"

    mkdir -p "$DOWNLOADED_PATH/$LANG"

    # English is the largest
    # 1.7G  downloaded/en/page.sql.gz
    # 6.2G  downloaded/en/pagelinks.sql.gz
    # 355M  downloaded/en/langlinks.sql.gz
    # 128M  downloaded/en/redirect.sql.gz

    # Smaller language Turkish
    #  53M  downloaded/tr/page.sql.gz
    # 176M  downloaded/tr/pagelinks.sql.gz
    # 106M  downloaded/tr/langlinks.sql.gz
    # 3.2M  downloaded/tr/redirect.sql.gz

    download https://$WIKIMEDIA_HOST/${LANG}wiki/$WIKIPEDIA_DATE/${LANG}wiki-$WIKIPEDIA_DATE-page.sql.gz      "$DOWNLOADED_PATH/$LANG/page.sql.gz"
    download https://$WIKIMEDIA_HOST/${LANG}wiki/$WIKIPEDIA_DATE/${LANG}wiki-$WIKIPEDIA_DATE-pagelinks.sql.gz "$DOWNLOADED_PATH/$LANG/pagelinks.sql.gz"
    download https://$WIKIMEDIA_HOST/${LANG}wiki/$WIKIPEDIA_DATE/${LANG}wiki-$WIKIPEDIA_DATE-langlinks.sql.gz "$DOWNLOADED_PATH/$LANG/langlinks.sql.gz"
    download https://$WIKIMEDIA_HOST/${LANG}wiki/$WIKIPEDIA_DATE/${LANG}wiki-$WIKIPEDIA_DATE-redirect.sql.gz  "$DOWNLOADED_PATH/$LANG/redirect.sql.gz"
done
