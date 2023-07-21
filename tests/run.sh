#!/bin/bash
cat tests/filter_pagelinks.test1.txt | bin/filter_pagelinks.py > out.txt
diff --brief out.txt tests/filter_pagelinks.test1expected.txt || exit 1

cat tests/filter_langlinks.test1.txt | bin/filter_langlinks.py > out.txt
diff --brief out.txt tests/filter_langlinks.test1expected.txt || exit 1

cat tests/filter_wikidata_geo_tags.test1.txt | bin/filter_wikidata_geo_tags.py > out.txt
diff --brief out.txt tests/filter_wikidata_geo_tags.test1expected.txt || exit 1
