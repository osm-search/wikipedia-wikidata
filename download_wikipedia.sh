#!/bin/bash

# languages to process (refer to List of Wikipedias here: https://en.wikipedia.org/wiki/List_of_Wikipedias)
# requires Bash 4.0
readarray -t LANGUAGES < languages.txt

# List of mirrors https://dumps.wikimedia.org/mirrors.html
# Download using main server: 150 minutes, mirror: 40 minutes
# HOST="dumps.wikimedia.org"
HOST="wikimedia.bringyour.com"

# or 'latest'
DATE='20210901'
DOWNLOADED_PATH="downloaded"

echo "====================================================================="
echo "Download individual wikipedia language tables dumps"
echo "====================================================================="

download() {
    if [ -e "$2" ]; then
        echo "file $2 already exists, skipping"
        return
    fi
    echo "Downloading $1 > $2"
    wget -O "$2" --quiet --no-clobber --tries=3 "$1"
    if [ ! -s "$2" ]; then
        echo "downloaded file $2 is empty, please retry later"
        rm -f "$2"
    fi
}

for LANG in "${LANGUAGES[@]}"
do
    echo "Language: $LANG"

    mkdir -p "$DOWNLOADED_PATH/$LANG"

    # English is the largest
    # 1.7G  page.sql.gz
    # 6.2G  pagelinks.sql.gz
    # 355M  langlinks.sql.gz
    # 128M  redirect.sql.gz

    # example of smaller languge Turkish
    #  53M  page.sql.gz
    # 176M  pagelinks.sql.gz
    # 106M  langlinks.sql.gz
    # 3.2M  redirect.sql.gz

    download https://$HOST/${LANG}wiki/$DATE/${LANG}wiki-$DATE-page.sql.gz $DOWNLOADED_PATH/$LANG/page.sql.gz
    download https://$HOST/${LANG}wiki/$DATE/${LANG}wiki-$DATE-pagelinks.sql.gz $DOWNLOADED_PATH/$LANG/pagelinks.sql.gz
    download https://$HOST/${LANG}wiki/$DATE/${LANG}wiki-$DATE-langlinks.sql.gz $DOWNLOADED_PATH/$LANG/langlinks.sql.gz
    download https://$HOST/${LANG}wiki/$DATE/${LANG}wiki-$DATE-redirect.sql.gz $DOWNLOADED_PATH/$LANG/redirect.sql.gz
done

echo "all done."
