#!/bin/bash

#
# Single script to do all processing from scratch. Run it or
# use as guide how to run the individual steps.
#
# Example to add timestamps and create a logfile:
# time ./complete_run.sh 2>&1 | ts -s "[%H:%M:%S]" | tee "$(date +"%Y%m%d").$$.log"


./install_dependencies.sh

export BUILDID=wiki_build_20230201c
export WIKIPEDIA_DATE=20230201 # check https://wikimedia.bringyour.com/enwiki/
export WIKIDATA_DATE=20230201 # check https://wikimedia.bringyour.com/wikidatawiki/
export LANGUAGES=$(grep -v '^#' config/languages.txt | tr "\n" ",")
# export LANGUAGES=de,nl
export DATABASE_NAME=$BUILDID
export DATABASE_TABLESPACE=extraspace # default is pg_default

./steps/wikipedia_download.sh
./steps/wikidata_download.sh
./steps/wikidata_api_fetch_placetypes.sh

./steps/wikipedia_sql2csv.sh
./steps/wikidata_sql2csv.sh

# dropdb --if-exists $DATABASE_NAME
createdb --tablespace=extraspace $DATABASE_NAME
./steps/wikipedia_import.sh
./steps/wikidata_import.sh

./steps/wikipedia_process.sh
./steps/wikidata_process.sh

./steps/output.sh
# ./steps/cleanup.sh
