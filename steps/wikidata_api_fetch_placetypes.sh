#!/bin/bash

# set defaults
: ${BUILDID:=latest}

DOWNLOADED_PATH="$BUILDID/downloaded/wikidata"
TEMP_PATH=$DOWNLOADED_PATH/tmp

if [[ -e $DOWNLOADED_PATH/wikidata_place_dump.csv.gz ]]; then
    echo "Output file $DOWNLOADED_PATH/wikidata_place_dump.csv.gz already exists. Won't fetch again."
    exit 0
fi

echo "====================================================================="
echo "Get wikidata places from wikidata query API"
echo "====================================================================="

# We create a mapping of QID->place type QID
# for example 'Q6922586;Q130003' (Mount Olympus Ski Area -> ski resort)
# 
# Takes about 30 minutes for 300 place types.
#
# The input wikidata_place_types.txt has the format
# Q1303167;barn
# Q130003;ski resort
# Q12518;tower
# The second column is optional.
#
# We tried to come up with a list of geographic related types but wikidata hierarchy
# is complex. You'd need to know what a Raion is (administrative unit of post-Soviet
# states) or a Bight. Many place types will be too broad, too narrow or even missing.
# It's best effort.
#
# wdtaxonomy (https://github.com/nichtich/wikidata-taxonomy) runs SPARQL queries
# against wikidata servers. Add --sparql to see the query. Example SPARQL query:
#
#     SELECT ?item ?broader ?sites WITH {
#       SELECT DISTINCT ?item { ?item wdt:P279* wd:Q82794 }
#     } AS %items WHERE {
#       INCLUDE %items .
#       OPTIONAL { ?item wdt:P279 ?broader } .
#       {
#         SELECT ?item (count(distinct ?site) as ?sites) {
#           INCLUDE %items.
#           OPTIONAL { ?site schema:about ?item }
#         } GROUP BY ?item
#       }
#     }
#
# The queries can time out (60 second limit). If that's the case we need to further
# subdivide the place type. For example Q486972 (human settlement) has too many
# instances. We run "wdtaxonomy Q486972 | grep '^├─'" which prints a long list
# ├──municipality (Q15284) •106 ×4208 ↑↑↑↑
# ├──trading post (Q39463) •14 ×97 ↑
# ├──monastery (Q44613) •100 ×13536 ↑↑↑↑↑
# ├──barangay (Q61878) •39 ×3524 ↑
# ├──county seat (Q62049) •34 ×1694 ↑
#
# Some instances don't have titles, e.g. https://www.wikidata.org/wiki/Q17218407
# but can still be assigned to wikipedia articles, in this case
# https://ja.wikipedia.org/wiki/%E3%82%81%E3%81%8C%E3%81%B2%E3%82%89%E3%82%B9%E3%82%AD%E3%83%BC%E5%A0%B4
# so we leave them in.

mkdir -p $DOWNLOADED_PATH
mkdir -p $TEMP_PATH

echo "Number of place types:"
wc -l config/wikidata_place_types.txt
echo -n > $DOWNLOADED_PATH/wikidata_place_dump.csv

while read PT_LINE ; do
    QID=$(echo $PT_LINE | sed 's/;.*//' )
    NAME=$(echo $PT_LINE | sed 's/^.*;//' )

    # Querying for place type Q205495 (petrol station)...
    echo "Querying for place type $QID ($NAME)..."

    # Example response from wdtaxonomy in CSV format for readability:
    # level,id,label,sites,instances,parents
    # [...]
    # -,Q110941628,Tegatayama Ski Area,0,0,
    # -,Q111016306,Ski resort Říčky,0,0,
    # -,Q111016347,Ski resort Deštné v Orlických horách,0,0,
    # -,Q111818006,Lively Ski Hill,0,0,
    # -,Q111983623,Falls Creek Alpine Resort,0,0,
    # -,Q1535041,summer skiing area,3,0,^^
    # -,Q2292158,,1,0,
    # -,Q5136446,Club skifield,1,0,
    # --,Q6922586,Mount Olympus Ski Area,0,0,
    # -,Q30752692,,1,0,
    #
    # For faster queries we use --no-instancecount and --no-labels
    # Now the columns are actually 'level,id,label,sites,parents' with 'label' always empty.
    # Unclear why for TSV the header is still commas, likely a bug in wdtaxonomy
    #
    # We don't care about parents ('^^', so called broader subcategories) in the last column.
    # We filter subcategoies, e.g. 'Club skifield', we're only interested in the children
    # (instances). Subcategories have 'sites' value > 0
    #

    wdtaxonomy $QID --instances --no-instancecount --no-labels --format tsv | \
    cut  -f1-4 | \
    grep -e "[[:space:]]0$" | \
    cut -f2 | \
    sort | \
    awk -v qid=$QID '{print $0 ","qid}' > $TEMP_PATH/$QID.csv
    wc -l $TEMP_PATH/$QID.csv

    # output example:
    # Q97774986,Q130003
    # Q980500,Q130003
    # Q988298,Q130003
    # Q991719,Q130003
    # Q992902,Q130003
    # Q995986,Q130003

    cat $TEMP_PATH/$QID.csv >> $DOWNLOADED_PATH/wikidata_place_dump.csv
    rm $TEMP_PATH/$QID.csv
done < config/wikidata_place_types.txt

# Non-Q is less than 20, not sure what they mean
#    L673595,Q4830453
#    P750,Q4830453
#    L162425-S2,Q40357
# uniq saves 4% lines
# 470MB compressed 72MB
grep '^Q' $DOWNLOADED_PATH/wikidata_place_dump.csv | \
uniq | \
pigz -f -9 > $DOWNLOADED_PATH/wikidata_place_dump.csv.gz

cp config/wikidata_place_type_levels.csv $DOWNLOADED_PATH
# temp should be empty but if not then that should be fine, too
rmdir $TEMP_PATH

du -h $DOWNLOADED_PATH
