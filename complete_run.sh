#!/bin/bash

#
# Single script to do all processing from scratch. Run it or
# use as guide how to run the individual steps.
#

./install_dependencies.sh

./download_wikipedia.sh
./download_wikidata.sh
./download_wikidata_placetypes.sh

./import_wikipedia.sh
./import_wikidata.sh

./process_wikipedia.sh
./process_wikidata.sh

./cleanup.sh
