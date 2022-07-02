#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}

# Languages as comma-separated string, e.g. 'en,fr,de'
: ${LANGUAGES:=bar,cy}
LANGUAGES_ARRAY=($(echo $LANGUAGES | tr ',' ' '))

psqlcmd() {
     psql --quiet $DATABASE_NAME
}



echo "====================================================================="
echo "Dropping intermediate wikipedia tables to conserve space"
echo "====================================================================="

for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "DROP TABLE ${LANG}pagelinks;"     | psqlcmd
    echo "DROP TABLE ${LANG}page;"          | psqlcmd
    echo "DROP TABLE ${LANG}langlinks;"     | psqlcmd
    echo "DROP TABLE ${LANG}redirect;"      | psqlcmd
    echo "DROP TABLE ${LANG}pagelinkcount;" | psqlcmd
done


echo "====================================================================="
echo "Dropping intermediate wikidata tables"
echo "====================================================================="

echo "DROP TABLE wikidata_place_dump;" | psqlcmd
echo "DROP TABLE geo_earth_primary;"   | psqlcmd
for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "DROP TABLE wikidata_${LANG}_pages;" | psqlcmd
done
