#!/bin/bash

OUT=$(python3 -c'from lib.languages import Languages; print(len(Languages.get_languages()))')
if [[ "$OUT" != "39" ]]; then
    echo 'expected 39'
    exit 1
fi

OUT=$(LANGUAGES=de,fr,it,en python3 -c'from lib.languages import Languages; print(len(Languages.get_languages()))')
if [[ "$OUT" != "4" ]]; then
    echo 'expected 4'
    exit 1
fi

cat tests/linktargets.txt | gzip > tests/linktargets.txt.gz
cat tests/filter_pagelinks.test1.txt | bin/filter_pagelinks.py tests/linktargets.txt.gz > out.txt
diff --brief out.txt tests/filter_pagelinks.test1expected.txt || exit 1
rm -f tests/linktargets.txt.gz

cat tests/filter_langlinks.test1.txt | bin/filter_langlinks.py > out.txt
diff --brief out.txt tests/filter_langlinks.test1expected.txt || exit 1

cat tests/filter_wikidata_geo_tags.test1.txt | bin/filter_wikidata_geo_tags.py > out.txt
diff --brief out.txt tests/filter_wikidata_geo_tags.test1expected.txt || exit 1

rm -f out.txt