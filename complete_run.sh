#!/bin/bash

#
# Single script to do all processing from scratch. Run it or
# use as guide how to run the individual steps.
#

./install_dependencies.sh

export BUILDID=wiki_build_202207
export LANGUAGES=$(grep -v '^#' languages.txt | tr "\n" ",")

./steps/wikipedia_download.sh
./steps/wikidata_download.sh
./steps/wikidata_api_fetch_placetypes.sh

# dropdb wikiprocessingdb
./steps/wikipedia_import.sh
./steps/wikidata_import.sh

./steps/wikipedia_process.sh
./steps/wikidata_process.sh

./steps/cleanup.sh
