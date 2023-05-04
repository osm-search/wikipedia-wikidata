#!/bin/bash

#
# Prints a YYYYMMDD date of the latest available date on 
# https://mirror.clarkson.edu/wikimedia/enwiki/
# We do some additional checks if the dumps are complete, too
#

debug() {
    # Comment out the following line to print debug information
    # echo "$@" 1>&2;
    echo -n ''
}


DATE=''

# Sets $DATE to first of the month (YYYYMMDD). If given a parameter then
# it substracts number of months
set_date_to_first_of_month() {
    MINUS_NUM_MONTHS=${1:-0}

    if [[ "$(uname)" == "Darwin" ]]; then
        DATE=$(date -v -${MINUS_NUM_MONTHS}m +%Y%m01) 
    else
        DATE=$(date --date="-$MINUS_NUM_MONTHS month" +%Y%m01) 
    fi
}


check_all_files_ready() {
    CHECK_DATE=$1
    debug "check_all_files_ready for $CHECK_DATE"

    # The complete dump for wikidata for example can take several weeks (metahistory7zdump
    # file ready after 15 days).
    #
    # The dumpruninfo.json files have this format:
    # {
    #   "jobs": {
    #     "imagetable": {
    #       "status": "done",
    #       "updated": "2023-02-01 08:27:30"
    #     },
    #     "imagelinkstable": {
    #       "status": "done",
    #       "updated": "2023-02-01 09:18:03"
    #     },
    #     "geotagstable": {
    #       "status": "done",
    #       "updated": "2023-02-01 10:01:50"
    #     },
    #     [...]
    #

    ANY_FILE_MISSING=0


    ##
    ## 1. Chinese (ZH) Wikipedia
    ## usually the last to be dumped
    ##
    # from wikipedia_download.sh
    WIKIPEDIA_REQUIRED_FILES="page pagelinks langlinks redirect"
    DUMP_RUN_INFO_URL="https://mirror.clarkson.edu/wikimedia/zhwiki/$CHECK_DATE/dumpruninfo.json"
    debug $DUMP_RUN_INFO_URL
    DUMP_RUN_INFO=$(curl -s --fail "$DUMP_RUN_INFO_URL")

    if [[ $? != 0 ]]; then
        debug "fetching from URL $DUMP_RUN_INFO_URL failed"
        return 1
    fi


    for FN in $WIKIPEDIA_REQUIRED_FILES; do
        TABLENAME=${FN//_/}table # redirect => redirecttable
        debug "checking status for table $TABLENAME"

        STATUS=$(echo "$DUMP_RUN_INFO" | TABLE=$TABLENAME jq -r '.jobs[env.TABLE].status')
        debug "  status: $STATUS"

        if [ "$STATUS" != "done" ]; then
            debug "$TABLENAME not ready yet"
            ANY_FILE_MISSING=1
        fi
    done



    ##
    ## 2. Wikidata
    ##
    # from wikidata_download.sh
    WIKIDATA_REQUIRED_FILES="geo_tags page wb_items_per_site"

    DUMP_RUN_INFO_URL="https://mirror.clarkson.edu/wikimedia/wikidatawiki/$CHECK_DATE/dumpruninfo.json"
    debug $DUMP_RUN_INFO_URL
    DUMP_RUN_INFO=$(curl -s --fail "$DUMP_RUN_INFO_URL")

    if [[ $? != 0 ]]; then
        debug "fetching from URL $DUMP_RUN_INFO_URL failed"
        return 1
    fi

    for FN in $WIKIDATA_REQUIRED_FILES; do
        TABLENAME=${FN//_/}table # wb_items_per_site => wbitemspersitetable
        debug "checking status for table $TABLENAME"

        STATUS=$(echo "$DUMP_RUN_INFO" | TABLE=$TABLENAME jq -r '.jobs[env.TABLE].status')
        debug "  status: $STATUS"

        if [ "$STATUS" != "done" ]; then
            debug "$TABLENAME not ready yet"
            ANY_FILE_MISSING=1
        fi
    done

    return $ANY_FILE_MISSING
}



#
# Usually you might try to get a list of dates from
# https://mirror.clarkson.edu/wikimedia/enwiki/ and then sort them, then look at status.html
# inside the directories.
#
# We want to avoid parsing HTML.
#
# Previous version of this script then looked at index.json
# (https://mirror.clarkson.edu/wikimedia/index.json) but the file is written at beginning
# of the export so first of month it would list files that don't exist yet.
#

for MINUS_NUM_MONTHS in 0 1 2 3; do
    set_date_to_first_of_month $MINUS_NUM_MONTHS
    check_all_files_ready $DATE
    # echo $?
    # echo $RES

    if [ $? == 0 ]; then
        echo "$DATE"
        exit 0
    fi
done

exit 1
