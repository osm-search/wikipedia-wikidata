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
    # CREATE TABLE `page` (
    #   `page_id`            int(8) unsigned     NOT NULL AUTO_INCREMENT,
    #   `page_namespace`     int(11)             NOT NULL DEFAULT 0,
    #   `page_title`         varbinary(255)      NOT NULL DEFAULT '',
    #   `page_restrictions`  tinyblob                     DEFAULT NULL,
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
    #   output 190MB compressed
    # Output columns: page_id, page_title

    unpigz -c $DOWNLOADED_PATH/${LANG}/page.sql.gz | \
    python3 bin/mysqldump_to_csv.py | \
    bin/filter_page.py | \
    pigz -9 > $CONVERTED_PATH/$LANG/pages.csv.gz


    echo "[language $LANG] Pagelinks table SQL => CSV"
    # CREATE TABLE `pagelinks` (
    #   `pl_from`            int(8) unsigned    NOT NULL DEFAULT 0,
    #   `pl_namespace`       int(11)            NOT NULL DEFAULT 0,
    #   `pl_title`           varbinary(255)     NOT NULL DEFAULT '',
    #   `pl_from_namespace`  int(11)            NOT NULL DEFAULT 0,
    #
    # Only interested in pl_namespace == 0 (articles)
    # English wikipedia:
    #   input 6.8GB compressed (54GB uncompressed)
    #   output 450MB compressed (3.1GB uncompressed)
    # Output columns: pl_title, count

    unpigz -c $DOWNLOADED_PATH/${LANG}/pagelinks.sql.gz | \
    python3 bin/mysqldump_to_csv.py | \
    bin/filter_pagelinks.py | \
    pigz -9 > $CONVERTED_PATH/$LANG/pagelinks.csv.gz


    echo "[language $LANG] langlinks table SQL => CSV"
    # CREATE TABLE `langlinks` (
    #   `ll_from`         int(8) unsigned   NOT NULL DEFAULT 0,
    #   `ll_lang`         varbinary(35)     NOT NULL DEFAULT '',
    #   `ll_title`        varbinary(255)    NOT NULL DEFAULT '',
    #
    # Output columns: ll_title, ll_from_page_id, ll_lang
    # Output is sorted by lang
    # English wikipedia:
    #   input 400MB compressed (1.5GB uncompressed)
    #   output 380MB compressed (1.3GB uncompressed)

    unpigz -c $DOWNLOADED_PATH/${LANG}/langlinks.sql.gz | \
    python3 bin/mysqldump_to_csv.py | \
    bin/filter_langlinks.py | \
    pigz -9 > $CONVERTED_PATH/$LANG/langlinks.csv.gz


    echo "[language $LANG] redirect table SQL => CSV"
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
    #   output 100MB compressed (300MB uncompressed)

    unpigz -c $DOWNLOADED_PATH/${LANG}/redirect.sql.gz | \
    python3 bin/mysqldump_to_csv.py | \
    bin/filter_redirect.py | \
    pigz -9 > $CONVERTED_PATH/$LANG/redirect.csv.gz

    du -h $CONVERTED_PATH/$LANG/*
done
