#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${LANGUAGES:=bar,cy}
LANGUAGES_ARRAY=($(echo $LANGUAGES | tr ',' ' '))

DOWNLOADED_PATH="$BUILDID/downloaded/wikipedia"
CONVERTED_PATH="$BUILDID/converted/wikipedia"

echo "====================================================================="
echo "Convert Wikipedia language tables"
echo "====================================================================="

for LANG in "${LANGUAGES_ARRAY[@]}"
do
    mkdir -p "$CONVERTED_PATH/$LANG/"

    echo "[language $LANG] Page table SQL => CSV"
    # https://www.mediawiki.org/wiki/Manual:Page_table
    #
    # CREATE TABLE `page` (
    #   `page_id`            int(8) unsigned     NOT NULL AUTO_INCREMENT,
    #   `page_namespace`     int(11)             NOT NULL DEFAULT 0,
    #   `page_title`         varbinary(255)      NOT NULL DEFAULT '',
    #   `page_is_redirect`   tinyint(1) unsigned NOT NULL DEFAULT 0,
    #   `page_is_new`        tinyint(1) unsigned NOT NULL DEFAULT 0,
    #   `page_random`        double unsigned     NOT NULL DEFAULT 0,
    #   `page_touched`       varbinary(14)       NOT NULL DEFAULT '',
    #   `page_links_updated` varbinary(14)                DEFAULT NULL,
    #   `page_latest`        int(8) unsigned     NOT NULL DEFAULT 0,
    #   `page_len`           int(8) unsigned     NOT NULL DEFAULT 0,
    #   `page_content_model` varbinary(32)                DEFAULT NULL,
    #   `page_lang`          varbinary(35)                DEFAULT NULL,
    #
    # Only interested in page_namespace == 0 (articles)
    # English wikipedia:
    #   input 1.9GB compressed
    #   output 200MB compressed
    # Output columns: page_id, page_title

    unpigz -c $DOWNLOADED_PATH/$LANG/page.sql.gz | \
    bin/mysqldump_to_csv.py | \
    bin/filter_page.py | \
    pigz -9 > $CONVERTED_PATH/$LANG/pages.csv.gz


    echo "[language $LANG] linktarget table SQL => CSV"
    # https://www.mediawiki.org/wiki/Manual:Linktarget_table
    #
    # CREATE TABLE `linktarget` (
    #   `lt_id`          bigint(20) unsigned  NOT NULL AUTO_INCREMENT,
    #   `lt_namespace`   int(11)              NOT NULL,
    #   `lt_title`       varbinary(255)       NOT NULL,
    #
    # Only interested in lt_namespace == 0 (articles)
    # English wikipedia:
    #   input 964MB compressed (100m rows)
    #   output 322MB compressed (30m rows)
    # Output columns: lt_id, lt_title

    unpigz -c $DOWNLOADED_PATH/${LANG}/linktarget.sql.gz | \
    bin/mysqldump_to_csv.py | \
    bin/filter_redirect.py  | \
    pigz -9 > $CONVERTED_PATH/$LANG/linktarget.csv.gz



    echo "[language $LANG] Pagelinks table SQL => CSV"
    # https://www.mediawiki.org/wiki/Manual:Pagelinks_table
    #
    # CREATE TABLE `pagelinks` (
    #   `pl_from`            int(8) unsigned     NOT NULL DEFAULT 0,
    #   `pl_namespace`       int(11)             NOT NULL DEFAULT 0,
    #   `pl_target_id`       bigint(20) unsigned NOT NULL,
    #
    # Only interested in target_ids that point to  == 0 (articles)
    # English wikipedia:
    #   input 6.8GB compressed
    #   output 200MB compressed
    # Output columns: lt_title (from linktarget file), count (unique pl_from)

    unpigz -c $DOWNLOADED_PATH/$LANG/pagelinks.sql.gz | \
    bin/mysqldump_to_csv.py | \
    bin/filter_pagelinks.py $CONVERTED_PATH/$LANG/linktarget.csv.gz | \
    pigz -9 > $CONVERTED_PATH/$LANG/pagelinks.csv.gz


    echo "[language $LANG] langlinks table SQL => CSV"
    # https://www.mediawiki.org/wiki/Manual:Langlinks_table
    #
    # CREATE TABLE `langlinks` (
    #   `ll_from`         int(8) unsigned   NOT NULL DEFAULT 0,
    #   `ll_lang`         varbinary(35)     NOT NULL DEFAULT '',
    #   `ll_title`        varbinary(255)    NOT NULL DEFAULT '',
    #
    # Output columns: ll_title, ll_from_page_id, ll_lang
    # Output is sorted by lang
    # English wikipedia:
    #   input 400MB compressed (1.5GB uncompressed)
    #   output 310MB compressed (1.3GB uncompressed)

    unpigz -c $DOWNLOADED_PATH/${LANG}/langlinks.sql.gz | \
    bin/mysqldump_to_csv.py | \
    bin/filter_langlinks.py | \
    pigz -9 > $CONVERTED_PATH/$LANG/langlinks.csv.gz




    echo "[language $LANG] redirect table SQL => CSV"
    # https://www.mediawiki.org/wiki/Manual:Redirect_table
    #
    # CREATE TABLE `redirect` (
    #   `rd_from`         int(8) unsigned   NOT NULL DEFAULT 0,
    #   `rd_namespace`    int(11)           NOT NULL DEFAULT 0,
    #   `rd_title`        varbinary(255)    NOT NULL DEFAULT '',
    #   `rd_interwiki`    varbinary(32)              DEFAULT NULL,
    #   `rd_fragment`     varbinary(255)             DEFAULT NULL,
    #
    # Only interested in rd_namespace = 0 (articles)
    # Output columns: rd_from_page_id, rd_title
    # English wikipedia:
    #   input 140MB compressed (530MB uncompressed)
    #   output 120MB compressed (300MB uncompressed)

    unpigz -c $DOWNLOADED_PATH/$LANG/redirect.sql.gz | \
    bin/mysqldump_to_csv.py | \
    bin/filter_redirect.py | \
    pigz -9 > $CONVERTED_PATH/$LANG/redirect.csv.gz

    du -h $CONVERTED_PATH/$LANG/*
done
