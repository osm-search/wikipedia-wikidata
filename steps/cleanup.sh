#!/bin/bash

# languages to process (refer to List of Wikipedias here: https://en.wikipedia.org/wiki/List_of_Wikipedias)
# requires Bash 4.0
readarray -t LANGUAGES < languages.txt




echo "====================================================================="
echo "Clean up intermediate wikipedia tables to conserve space"
echo "====================================================================="

for i in "${LANGUAGES[@]}"
do
    echo "DROP TABLE ${i}pagelinks;"     | psqlcmd
    echo "DROP TABLE ${i}page;"          | psqlcmd
    echo "DROP TABLE ${i}langlinks;"     | psqlcmd
    echo "DROP TABLE ${i}redirect;"      | psqlcmd
    echo "DROP TABLE ${i}pagelinkcount;" | psqlcmd
done


echo "====================================================================="
echo "Dropping intermediate wikidata tables"
echo "====================================================================="

echo "DROP TABLE wikidata_place_dump;" | psqlcmd
echo "DROP TABLE geo_earth_primary;" | psqlcmd
for i in "${LANGUAGES[@]}"
do
    echo "DROP TABLE wikidata_${i}_pages;" | psqlcmd
done
