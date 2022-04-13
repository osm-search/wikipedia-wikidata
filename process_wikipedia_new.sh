#!/bin/bash

# languages to process (refer to List of Wikipedias here: https://en.wikipedia.org/wiki/List_of_Wikipedias)
# requires Bash 4.0
readarray -t LANGUAGES < languages.txt

mkdir "output/"

echo "====================================================================="
echo "Process language tables and associated pagelink counts"
echo "====================================================================="

for LANG in "${LANGUAGES[@]}"

    echo "[language $LANG] wikipedia_redirect"
    #
    # Input is
    #   1. pages.csv (page_id, page_title)
    #   2. redirects.csv (rd_from_page_id, rd_title)
    # Both files are already sorted.
    #
    # We join both on page id.
    #
    # Output columns: country_code, rd_title, page_title
    #
    # English wikipedia:
    #   input 16m pages (590MB uncompressed), 12m redirects (300MB uncompressed)
    #   output 9m lines (400MB uncompressed, 140MB compressed)
    #
    # We use 'sort' to merge pages and redirects by id and create a stream, example:
    # 31250,page,Time-division_multiple_access
    # 31251,page,TACS
    # 31251,redirect,Total_Access_Communication_System
    # 31253,page,The_Prisoner
    # 31254,page,The_Junior_Woodchucks
    # 31254,redirect,Junior_Woodchucks
    # 31255,page,Theseus
    #
    # Then find matches. In this case the output is:
    # Total_Access_Communication_System,TACS
    # Junior_Woodchucks,The_Junior_Woodchucks

    # 'gunzip -c $file' is the same as 'zcat $file'
    sort --merge --numeric-sort \
      <(gunzip -c converted/$LANG/pages.csv.gz | sed 's/^\([0-9]\+\),/\1,page,/') \
      <(gunzip -c converted/$LANG/redirects.csv.gz | sed 's/^\([0-9]\+\),/\1,redirect,/') \
    | \
    bin/find_redirects.py | \
    sed "s/^/$LANG,/" | \
    gzip -9 > converted/$LANG/wikipedia_redirect.csv.gz
done

echo "create combined wikipedia_redirect"
# Combine all wikipedia_redirect files.
# We can just concatenate them.
# https://stackoverflow.com/questions/8005114/fast-concatenation-of-multiple-gzip-files
zcat converted/*/wikipedia_redirect.csv.gz > output/wikipedia_redirect.csv.gz
# About 500MB compressed, 35m lines



for LANG in "${LANGUAGES[@]}"
do
    echo "[language $LANG] Create pagelinkcounts.csv"
    #
    # pagelinks.csv file contains duplicates. We add a unique count as second
    # column.
    #
    # 'cat $file | sort | uniq -c' needs too much memory. Even giving it 16GB of RAM,
    # parallel processes, compressed temporary files it's slower than the approach
    # below.
    # We transverse the file and combine lines with same titles first. It requires
    # no memory and already cuts the input by 90% (English wikipedia: to 57m lines).
    # Next we sort and repeat.
    #
    # Output columns: page_title, count
    #
    # English wikipedia:
    #   input 770m lines (16GB uncompressed)
    #   output 26m lines (620MB uncompressed)
    #
    zcat converted/$LANG/pagelinks.csv.gz | \
    bin/count_first_column.py | \
    sort | \
    bin/summarize_counts.py | \
    gzip -9 > converted/$LANG/pagelinkcounts.csv.gz
done


for LANG in "${LANGUAGES[@]}"
do
    for LANGFROM in "${LANGUAGES[@]}"
    do
        ["$LANGFROM" -eq "$LANG"] && continue

        echo "[from language $LANGFROM] create pagelinkothercount_from_"
        #
        # 'other' means links from other wikipedia languages. We're looking
        # a langlinks, for example 'Londres' in Spanish links to 'London' in
        # English.
        # But we don't want to give London a count += 1. Instead it should
        # increase by the number of links the 'Londres' page has in Spanish.
        #
        # We create two files
        #
        # 1. langlinks_from_${LANGFROM}.csv
        #    columns: page_title_current_language,'langlink',link_title_other_language
        #
        #    London,langlink,Londres
        #    London_Borough_of_Camden,langlink,Camden (Londres)
        #    1944_Summer_Olympics,langlink,Juegos Olímpicos de Londres 1944
        #    2017_London_attack,langlink,Atentado de Londres de 2017
        #
        # 2. pagelinkcounts_from_${LANGFROM}.csv
        #    columns: pl_title, 'pagelinkcount', count
        #
        #    Londres,pagelinkcount,56448
        #    Camden_(Londres),pagelinkcount,160
        #    Juegos_Olímpicos_de_Londres_1944,pagelinkcount,37
        #    Atentado_de_Londres_de_junio_de_2017,pagelinkcount,27
        #
        # and then merge them. The output will be
        #    London,56448
        #    London_Borough_of_Camden,160
        #    1944_Summer_Olympics,37
        #    2017_London_attack,27

        zcat converted/$LANG/langlinks.csv.gz | \
        grep ",${LANGFROM}\r\?$" | \
        sed "s/,${LANGFROM}\r\?$//" | \
        grep -v "^," | \
        bin/replace_page_id.py converted/$LANG/pages.csv.gz | \
        sed 's/\r\?$/,langlink/' | \
        csvcut -c 2,3,1 | \
        sort | \
        gzip -9 \
        > converted/$LANG/langlinks_from_${LANGFROM}.csv.gz

        zcat converted/$j/pagelinkcounts.csv.gz  | \
        sed 's/\r\?$/,pagelinkcount/' | \
        csvcut -c 1,3,2 | \
        sort | \
        gzip -9 \
        > converted/$LANG/pagelinkcounts_from_${LANGFROM}.csv.gz

        # 'gunzip -c $file' is the same as 'zcat $file'
        sort --merge \
          <(gunzip -c converted/$LANG/langlinks_from_${LANGFROM}.csv.gz) \
          <(gunzip -c converted/$LANG/pagelinkcounts_from_${LANGFROM}.csv.gz) \
        | \
        bin/find_inlinks.py | \
        gzip -9 \
        > converted/$LANG/pagelinkothercount_from_${LANGFROM}.csv.gz
    done
#    zcat converted/$LANG/pagelinkothercount_from_*.csv.gz
done

for LANG in "${LANGUAGES[@]}"
do
    echo "[language $LANG] create wikipedia_article"
    #
    # We need two files
    # 1. pagelinkcount
    #    <page_title>,<number of links>
    # 2. pagelinkothercount
    #    <page_title>,<number of links from other languages>
    # 3. totalcount (1+2)
    #
    # 4. importance
    #     "UPDATE wikipedia_article
    #     SET importance = LOG(totalcount)/LOG((SELECT MAX(totalcount) FROM wikipedia_article))
    #     ;"
    #
    # 5. lat,lon,osm_type,osm_id from wikidata
    #
done

# echo "CREATE TABLE wikipedia_article (
#         language    text NOT NULL,
#         title       text NOT NULL,
#         langcount   integer,
#         othercount  integer,
#         totalcount  integer,
#         lat double  precision,
#         lon double  precision,
#         importance  double precision,
#         title_en    text,
#         osm_type    character(1),
#         osm_id      bigint
#       );" | psqlcmd


echo 'all done.'