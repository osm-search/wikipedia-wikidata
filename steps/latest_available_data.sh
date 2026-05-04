#!/bin/bash

#
# Prints a YYYYMMDD date of the latest available dump on the configured
# wikimedia mirror.
#
# Two checks:
#
#   1. zhwiki and wikidatawiki dumpruninfo.json report all required tables
#      as "done".
#      But that just indicated the dump completed, not that the mirror
#      server downloaded all files. Using the last file alphabetically
#      is a good indication, but there's no guarantee which files get
#      downloaded by the mirror server first or last.
#
#   2. The .sql.gz files exist on the mirror (with non-zero size)
#      This causes many HTTP requests (curl -I only) but avoid headaches
#      later.

: ${WIKIMEDIA_HOST:=wikidata.aerotechnet.com}

# You can overwrite LANGUAGEs, e.g. when testing or for CI.
if [ -z "$LANGUAGES" ]; then
    if [ -f config/languages.txt ]; then
        LANGUAGES=$(grep -v '^#' config/languages.txt | tr "\n" "," | sed 's/,$//')
    else
        echo "ERROR: LANGUAGES not set and config/languages.txt not found" >&2
        exit 2
    fi
fi
LANGUAGES_ARRAY=($(echo $LANGUAGES | tr ',' ' '))

debug() {
    # Comment out the following line to print debug information
    # echo "$@" 1>&2
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

# Returns 0 if URL responds 2xx with non-zero Content-Length.
mirror_file_present() {
    URL=$1
    HEADERS=$(curl -sI --fail --max-time 15 "$URL" 2>/dev/null)
    if [[ $? != 0 ]]; then
        return 1
    fi
    SIZE=$(echo "$HEADERS" | grep -i '^content-length:' | tail -1 | awk '{print $2}' | tr -d '\r')
    if [ -z "$SIZE" ] || [ "$SIZE" = "0" ]; then
        return 1
    fi
    return 0
}

# Checks that all required table jobs in $WIKI/$CHECK_DATE/dumpruninfo.json
# are status=done. Returns 1 on any missing/not-done table, or fetch failure.
check_dumprun_done() {
    WIKI=$1
    REQUIRED_FILES=$2
    DUMP_RUN_INFO_URL="https://$WIKIMEDIA_HOST/$WIKI/$CHECK_DATE/dumpruninfo.json"
    debug $DUMP_RUN_INFO_URL
    DUMP_RUN_INFO=$(curl -s --fail "$DUMP_RUN_INFO_URL")
    if [[ $? != 0 ]]; then
        debug "fetching from URL $DUMP_RUN_INFO_URL failed"
        return 1
    fi

    for FN in $REQUIRED_FILES; do
        TABLENAME=${FN//_/}table # redirect => redirecttable, wb_items_per_site => wbitemspersitetable
        debug "checking status for table $TABLENAME"
        STATUS=$(echo "$DUMP_RUN_INFO" | TABLE=$TABLENAME jq -r '.jobs[env.TABLE].status')
        debug "  status: $STATUS"
        if [ "$STATUS" != "done" ]; then
            debug "$WIKI/$CHECK_DATE: $TABLENAME not done"
            return 1
        fi
    done
    return 0
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
    #     "imagetable":      { "status": "done", "updated": "2023-02-01 08:27:30" },
    #     "imagelinkstable": { "status": "done", "updated": "2023-02-01 09:18:03" },
    #     "geotagstable":    { "status": "done", "updated": "2023-02-01 10:01:50" },
    #     [...]

    # 1. Upstream dump completion. zhwiki is usually the last large wiki to
    #    finish; wikidatawiki has its own schedule.
    check_dumprun_done zhwiki "page pagelinks langlinks linktarget redirect" || return 1
    check_dumprun_done wikidatawiki "geo_tags page wb_items_per_site" || return 1

    # 2. Mirror sync. Do the file really exist? dumpruninfo.json only contains a list
    #    of dumps on the dump server, not yet the mirror.
    for WIKILANG in "${LANGUAGES_ARRAY[@]}"; do
        URL="https://$WIKIMEDIA_HOST/${WIKILANG}wiki/$CHECK_DATE/${WIKILANG}wiki-$CHECK_DATE-page.sql.gz"
        if ! mirror_file_present "$URL"; then
            debug "mirror missing or empty: $URL"
            return 1
        fi
    done

    # And the actual wikidata dump files we'll fetch (no per-language fan-out).
    for FN in geo_tags page wb_items_per_site; do
        URL="https://$WIKIMEDIA_HOST/wikidatawiki/$CHECK_DATE/wikidatawiki-$CHECK_DATE-$FN.sql.gz"
        if ! mirror_file_present "$URL"; then
            debug "mirror missing or empty: $URL"
            return 1
        fi
    done

    return 0
}

# Find dates in directory names. We need to parse HTML.
CONTENT=$(curl -s -S --fail "https://$WIKIMEDIA_HOST/enwiki/")
for DATE in $(echo $CONTENT | grep -oE '20[0-9]{6}' | sort -nr); do
    if check_all_files_ready $DATE; then
        echo "$DATE"
        exit 0
    fi
done

exit 1
