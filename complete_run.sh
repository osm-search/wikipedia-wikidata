#!/bin/bash

#
# Single script to do all processing from scratch. Run it or
# use as guide how to run the individual steps.
#
# Example to add timestamps and create a logfile:
# time ./complete_run.sh 2>&1 | ts -s "[%H:%M:%S]" | tee "$(date +"%Y%m%d").$$.log"

# Inspect exit code of each step. 'set -e' or '|| exit' would also work but
# with a function we have more verbose logging.
run_step() {
    # $* and $@ are both all positional parameter to this function
    # $* is string representation
    # $@ is an array, what actually gets run
    echo "===> Running: $*"
    "$@"
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "STEP FAILED (exit $status): $*"
        echo "Aborting run."
        exit "$status"
    fi
}

run_step ./install_dependencies.sh

# checks https://ftp.acc.umu.se/mirror/wikimedia.org/dumps/enwiki/
#    and https://ftp.acc.umu.se/mirror/wikimedia.org/dumps/wikidatawiki/
LATEST_DATE=$(./steps/latest_available_data.sh) # yyyymmdd

# If the mirror is outdated or missing files then LATEST_DATE can be empty.
if [ -z "$LATEST_DATE" ]; then
    echo "No complete wikimedia dump available on mirror yet. Skipping run."
    exit 0
fi

export WIKIPEDIA_DATE=$LATEST_DATE
export WIKIDATA_DATE=$LATEST_DATE
export BUILDID=wikimedia_build_$(date +"%Y%m%d")
export LANGUAGES=$(grep -v '^#' config/languages.txt | tr "\n" ",")
# export LANGUAGES=de,nl
export DATABASE_NAME=$BUILDID

run_step ./steps/wikipedia_download.sh
run_step ./steps/wikidata_download.sh
run_step ./steps/wikidata_api_fetch_placetypes.sh

run_step ./steps/wikipedia_sql2csv.sh
run_step ./steps/wikidata_sql2csv.sh

# dropdb --if-exists $DATABASE_NAME
# createdb is expected to fail on a re-run (DB already exists), so it is
# intentionally not wrapped in run_step.
createdb $DATABASE_NAME
run_step ./steps/wikipedia_import.sh
run_step ./steps/wikidata_import.sh

run_step ./steps/wikipedia_process.sh
run_step ./steps/wikidata_process.sh

run_step ./steps/report_database_size.sh
run_step ./steps/output.sh
# ./steps/cleanup.sh

echo "Finished."
