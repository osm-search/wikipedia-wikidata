#!/bin/bash

# https://wikimedia.bringyour.com/wikidatawiki/
HOST="wikimedia.bringyour.com"

# or 'latest'
DATE='20210901'
DOWNLOADED_PATH="wikidata"

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


echo "====================================================================="
echo "Download wikidata dump tables"
echo "====================================================================="

# 114M  wikidatawiki-latest-geo_tags.sql.gz
# 1.7G  wikidatawiki-latest-page.sql.gz
# 1.2G  wikidatawiki-latest-wb_items_per_site.sql.gz
download https://$HOST/wikidatawiki/latest/wikidatawiki-latest-geo_tags.sql.gz $DOWNLOADED_PATH/geo_tags.sql.gz
download https://$HOST/wikidatawiki/latest/wikidatawiki-latest-page.sql.gz $DOWNLOADED_PATH/page.sql.gz
download https://$HOST/wikidatawiki/latest/wikidatawiki-latest-wb_items_per_site.sql.gz $DOWNLOADED_PATH/wb_items_per_site.sql.gz


echo "====================================================================="
echo "Get wikidata places from wikidata query API"
echo "====================================================================="

echo "Number of place types:"
wc -l wikidata_place_types.txt

while read F  ; do
    echo "Querying for place type $F..."
    # P31 = 'is instance of'
    # P279 = 'is subclass of'
    wget --quiet "https://query.wikidata.org/bigdata/namespace/wdq/sparql?format=json&query=SELECT ?item WHERE{?item wdt:P31*/wdt:P279*wd:$F;}" -O "$DOWNLOADED_PATH/$F.json"
    jq -r '.results | .[] | .[] | [.item.value] | @csv' "$DOWNLOADED_PATH/$F.json" >> "$DOWNLOADED_PATH/$F.txt"
    awk -v qid=$F '{print $0 ","qid}' "$DOWNLOADED_PATH/$F.txt" | sed -e 's!"http://www.wikidata.org/entity/!!' | sed 's/"//g' >> "$DOWNLOADED_PATH/$F.csv"
    cat "$DOWNLOADED_PATH/$F.csv" >> wikidata_place_dump.csv
    # rm $F.json $F.txt $F.csv
done < wikidata_place_types.txt

# for example Q177634 ("community" https://www.wikidata.org/wiki/Q177634) wget outputs 300MB

# timeout after 1 minute

#         "value" : "http://www.wikidata.org/entity/Q13544783"
#       SPARQL-QUERY: queryStr=SELECT ?item WHERE{?item wdt:P31*/wdt:P279*wd:Q177634;}
# java.util.concurrent.TimeoutException
# 	at java.util.concurrent.FutureTask.get(FutureTask.java:205)

# try 'and in germany'
# ?item wdt:P131+ wd:Q46; wdt:P31*/wdt:P279*wd:Q177634;

# 30 minutes
Querying for place type Q82794...
parse error: Unfinished string at EOF at line 16033724, column 0
Querying for place type Q811979...
parse error: Unfinished string at EOF at line 17570284, column 0
Querying for place type Q56061...
parse error: Unfinished string at EOF at line 12183264, column 0
Querying for place type Q486972...
parse error: Unfinished string at EOF at line 13073734, column 0
Querying for place type Q41176...
parse error: Invalid numeric literal at line 11218978, column 35
Querying for place type Q271669...
parse error: Invalid numeric literal at line 9746574, column 21
Querying for place type Q177634...
parse error: Invalid numeric literal at line 12553332, column 14
Querying for place type Q17334923...
parse error: Unfinished string at EOF at line 7496184, column 0

1GB
