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

#
# Usually you might try to get a list of dates from
# https://mirror.clarkson.edu/wikimedia/enwiki/ and then sort them, then look at status.html
# inside the directories.
#
# We want to avoid parsing HTML.
#
# Instead we look at index.json which is 3 megabyte and contains almost too much
# information.
#
# {
#   "status": "done",
#   "updated": "2023-02-01 09:58:04",
#   "files": {
#     "enwiki-20230201-page.sql.gz": {
#       "size": 2068890771,
#       "url": "/enwiki/20230201/enwiki-20230201-page.sql.gz",
#       "md5": "b8f692170b3d9ca11157d1def489fbce",
#       "sha1": "7915d4d5d8baa8f40d49c93786cd77b9b9edd269"
#     }
#   }
# }
# 
# We look for enwiki because english language is the largest database and takes the longest
# to dump. We then assume all other languages are also ready.
#
#
INDEX_JSON_URL="https://mirror.clarkson.edu/wikimedia/index.json"
debug "$INDEX_JSON_URL"
INDEX_JSON=$(curl -s "$INDEX_JSON_URL" | jq '.wikis.enwiki.jobs.pagetable')
if [[ "$INDEX_JSON" = "" ]]; then
	debug "fetching from URL $INDEX_JSON_URL failed"
	exit 1
fi

LATEST_FILENAME=$(echo $INDEX_JSON | jq -r '.files | keys[-1]')
debug "LATEST_FILENAME: $LATEST_FILENAME"
# enwiki-20230201-page.sql.gz

# Split into array, use second item
PARTS=(${LATEST_FILENAME//-/ })
LATEST_DATE=${PARTS[1]}
debug "LATEST_DATE: $LATEST_DATE"

if [[ "$LATEST_DATE" = "" ]]; then
	debug "No date found"
	exit 1
fi



#
# Now double-check all files we're interested are ready. The complete dump for wikidata for
# example can take severla weeks (metahistory7zdump file ready after 15 days).
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
## 1. English Wikipedia
##
# from wikipedia_download.sh
WIKIPEDIA_REQUIRED_FILES="page pagelinks langlinks redirect"
DUMP_RUN_INFO_URL="https://mirror.clarkson.edu/wikimedia/enwiki/$LATEST_DATE/dumpruninfo.json"
debug $DUMP_RUN_INFO_URL
DUMP_RUN_INFO=$(curl -s "$DUMP_RUN_INFO_URL")

if [[ "$DUMP_RUN_INFO" = "" ]]; then
	debug "fetching from URL $DUMP_RUN_INFO_URL failed"
	exit 1
fi


for FN in $WIKIPEDIA_REQUIRED_FILES; do
	TABLENAME=${FN//_/}table # redirect => redirecttable
	debug "checking status for table $TABLENAME"

	STATUS=$(echo $DUMP_RUN_INFO | TABLE=$TABLENAME jq -r '.jobs[env.TABLE].status')
	debug "  status: $STATUS"

	if [[ $STATUS -ne 'done' ]]; then
		debug "$TABLENAME not ready yet"
		$ANY_FILE_MISSING=1
	fi
done



##
## 2. Wikidata
##
# from wikidata_download.sh
WIKIDATA_REQUIRED_FILES="geo_tags page wb_items_per_site"

DUMP_RUN_INFO_URL="https://mirror.clarkson.edu/wikimedia/enwiki/$LATEST_DATE/dumpruninfo.json"
debug $DUMP_RUN_INFO_URL
DUMP_RUN_INFO=$(curl -s "$DUMP_RUN_INFO_URL")

if [[ "$DUMP_RUN_INFO" = "" ]]; then
	debug "fetching from URL $DUMP_RUN_INFO_URL failed"
	exit 1
fi

for FN in $WIKIDATA_REQUIRED_FILES; do
	TABLENAME=${FN//_/}table # wb_items_per_site => wbitemspersitetable
	debug "checking status for table $TABLENAME"

	STATUS=$(echo $DUMP_RUN_INFO | TABLE=$TABLENAME jq -r '.jobs[env.TABLE].status')
	debug "  status: $STATUS"

	if [[ $STATUS -ne 'done' ]]; then
		debug "$TABLENAME not ready yet"
		$ANY_FILE_MISSING=1
	fi
done


##
## Finally print the YYYYMMDD date
##
debug "ANY_FILE_MISSING: $ANY_FILE_MISSING"
if [[ $ANY_FILE_MISSING = 0 ]]; then
	echo $LATEST_DATE
fi

exit 0
