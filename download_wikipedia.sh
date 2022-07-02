#!/bin/bash

download() {
     echo "Downloading $1"
     header='--header=User-Agent:Osm-search-Bot/1(https://github.com/osm-search/wikipedia-wikidata)'
     wget --no-clobber "$header" --tries=3 "$1" 
}

# languages to process (refer to List of Wikipedias here: https://en.wikipedia.org/wiki/List_of_Wikipedias)
# requires Bash 4.0
readarray -t LANGUAGES < languages.txt

echo "====================================================================="
echo "Download individual wikipedia language tables"
echo "====================================================================="


for LANG in "${LANGUAGES[@]}"
do
    echo "Language: $LANG"

    # english is the largest
    # 1.7G  enwiki-latest-page.sql.gz
    # 6.2G  enwiki-latest-pagelinks.sql.gz
    # 355M  enwiki-latest-langlinks.sql.gz
    # 128M  enwiki-latest-redirect.sql.gz

    # example of smaller languge turkish
    #  53M  trwiki-latest-page.sql.gz
    # 176M  trwiki-latest-pagelinks.sql.gz
    # 106M  trwiki-latest-langlinks.sql.gz
    # 3.2M  trwiki-latest-redirect.sql.gz

    download https://dumps.wikimedia.org/${LANG}wiki/latest/${LANG}wiki-latest-page.sql.gz
    download https://dumps.wikimedia.org/${LANG}wiki/latest/${LANG}wiki-latest-pagelinks.sql.gz
    download https://dumps.wikimedia.org/${LANG}wiki/latest/${LANG}wiki-latest-langlinks.sql.gz
    download https://dumps.wikimedia.org/${LANG}wiki/latest/${LANG}wiki-latest-redirect.sql.gz
done
