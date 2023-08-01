#!/bin/bash

#
# Single script to do all processing from scratch. Run it or
# use as guide how to run the individual steps.
#
# Example to add timestamps and create a logfile:
# time ./complete_run.sh 2>&1 | ts -s "[%H:%M:%S]" | tee "$(date +"%Y%m%d").$$.log"


./install_dependencies.sh

# checks https://mirror.clarkson.edu/wikimedia/enwiki/
#    and https://mirror.clarkson.edu/wikimedia/wikidatawiki/
LATEST_DATE=$(./steps/latest_available_data.sh) # yyyymmdd

export WIKIPEDIA_DATE=$LATEST_DATE
export WIKIDATA_DATE=$LATEST_DATE
export BUILDID=wikimedia_build_$(date +"%Y%m%d")
export LANGUAGES=$(grep -v '^#' config/languages.txt | tr "\n" ",")
# export LANGUAGES=de,nl
export DATABASE_NAME=$BUILDID

./steps/wikipedia_download.sh
./steps/wikidata_download.sh
./steps/wikidata_api_fetch_placetypes.sh

./steps/wikipedia_sql2csv.sh
./steps/wikidata_sql2csv.sh

# dropdb --if-exists $DATABASE_NAME
createdb $DATABASE_NAME
./steps/wikipedia_import.sh
./steps/wikidata_import.sh

./steps/wikipedia_process.sh
./steps/wikidata_process.sh

./steps/report_database_size.sh
./steps/output.sh
# ./steps/cleanup.sh

echo "Finished."