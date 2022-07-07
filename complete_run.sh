#!/bin/bash

#
# Single script to do all processing from scratch. Run it or
# use as guide how to run the individual steps.
#

./install_dependencies.sh

export BUILDID=wiki_build_20220620
export LANGUAGES=$(grep -v '^#' config/languages.txt | tr "\n" ",")
export DATABASE_NAME=wikiprocessingdb

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

./steps/cleanup.sh
