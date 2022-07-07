#!/bin/bash

# set defaults
: ${BUILDID:=latest}
# Languages as comma-separated string, e.g. 'en,fr,de'
: ${LANGUAGES:=bar,cy}
LANGUAGES_ARRAY=($(echo $LANGUAGES | tr ',' ' '))


DOWNLOADED_PATH="$BUILDID/downloaded/wikidata"
CONVERTED_PATH="$BUILDID/converted/wikidata"
mkdir -p $CONVERTED_PATH


###############################################################################
## GEO_TAGS
##
echo "wikidata_sql2csv geo_tags"

# MySQL schema inside the sql.gz file:
#
# CREATE TABLE `geo_tags` (
#   `gt_id`      int(10) unsigned NOT NULL AUTO_INCREMENT,
#   `gt_page_id` int(10) unsigned NOT NULL,
#   `gt_globe`   varbinary(32)    NOT NULL,
#   `gt_primary` tinyint(1)       NOT NULL,
#   `gt_lat`     decimal(11,8)              DEFAULT NULL,
#   `gt_lon`     decimal(11,8)              DEFAULT NULL,
#   `gt_dim`     int(11)                    DEFAULT NULL,
#   `gt_type`    varbinary(32)              DEFAULT NULL,
#   `gt_name`    varbinary(255)             DEFAULT NULL,
#   `gt_country` binary(2)                  DEFAULT NULL,
#   `gt_region`  varbinary(3)               DEFAULT NULL,

# Remove anything globe!=earth, primary!=1
# Round the coordinates
zcat $DOWNLOADED_PATH/geo_tags.sql.gz | \
python3 bin/mysqldump_to_csv.py | \
sed 's/\x0//g' | \
sed 's/\r\?//g' | \
grep ',earth,1,' | \
csvcut -c 2,5,6 | \
bin/round_coordinates.py | \
gzip -9 \
> $CONVERTED_PATH/geo_tags.csv.gz

# Input
#   134 MB (690 MB uncompressed)
# Output
#   89 MB (240 MB uncompressed)
#   8.4m entries
#   columns: page_id, lat, lon
# 4175,43.1924,-81.3158
# 4180,-26.0,121.0
# 4181,43.08333333,2.41666667
# 4187,51.76055556,14.33416667



###############################################################################
## PAGE
##

echo "wikidata_sql2csv page"

# MySQL schema inside the sql.gz file:
#
# CREATE TABLE `page` (
#   `page_id`            int(10) unsigned    NOT NULL AUTO_INCREMENT,
#   `page_namespace`     int(11)             NOT NULL,
#   `page_title`         varbinary(255)      NOT NULL,
#   `page_restrictions`  tinyblob                     DEFAULT NULL,
#   `page_is_redirect`   tinyint(3) unsigned NOT NULL DEFAULT 0,
#   `page_is_new`        tinyint(3) unsigned NOT NULL DEFAULT 0,
#   `page_random`        double unsigned     NOT NULL,
#   `page_touched`       binary(14)          NOT NULL,
#   `page_links_updated` varbinary(14)                DEFAULT NULL,
#   `page_latest`        int(10) unsigned    NOT NULL,
#   `page_len`           int(10) unsigned    NOT NULL,
#   `page_content_model` varbinary(32)                DEFAULT NULL,
#   `page_lang`          varbinary(35)                DEFAULT NULL,

# We remove all namespace != 0 (0=articles, 99% of the lines)
# page_lang isn't interesting, 'NULL' 99.999% of the time
# Remove all page_title that don't start with 'Q'

zcat $DOWNLOADED_PATH/page.sql.gz | \
python3 bin/mysqldump_to_csv.py | \
sed 's/\x0//g' | \
sed 's/\r\?//g' | \
csvcut -c 1,3,2 | \
grep -e ',0$' | \
sed 's/,0$//' | \
grep ',Q' | \
gzip -9 \
> $CONVERTED_PATH/page.csv.gz

# 34min
# Input
#   2.8GB, (3.1GB uncompresseed)
# Output
#   480MB, (1.8GB uncompressed)
#   3m lines
#   columns: page_id, page_title
#
# 12991,Q11474
# 12992,Q11475
# 12993,Q11476
# 12995,Q11477
# 12996,Q11478
# 12997,Q11479





###############################################################################
## WB_ITEMS_PER_SITE
##

echo "wikidata_sql2csv wb_items_per_site"

# MySQL schema inside the sql.gz file:
#
# CREATE TABLE `wb_items_per_site` (
#   `ips_row_id`    bigint(20) unsigned NOT NULL AUTO_INCREMENT,
#   `ips_item_id`   int(10) unsigned    NOT NULL,
#   `ips_site_id`   varbinary(32)       NOT NULL,
#   `ips_site_page` varbinary(310)      NOT NULL,

# Only considering languages we need, cuts down 80m lines to 52m
LISTLANG=${LANGUAGES_ARRAY[@]}
# ar bg ca cs da de en es
LANG_E_REGEX=",\(${LISTLANG// /\\|}\)wiki,"
# ,\(ar\|bg\|ca\|cs\|da\|de\|en...\)wiki,

zcat $DOWNLOADED_PATH/wb_items_per_site.sql.gz | \
python3 bin/mysqldump_to_csv.py | \
sed 's/\x0//g' | \
sed 's/\r\?//g' | \
grep -e "$LANG_E_REGEX" | \
csvcut -c 2,3,4 | \
gzip -9 \
> $CONVERTED_PATH/wb_items_per_site.csv.gz

# Input
#   1.4GB compressed, (4.7GB uncompressed)
# Output 
#   750MB compressed, (2.2GB uncompressed)
#   52m lines
#   columns: item_id, site_id, page (title)
# 576947,cawiki,Bryaninops amplus
# 2739322,cawiki,Bryneich
# 2927288,cawiki,Bréjaude
# 2912549,cawiki,Brúixola Brunton


du -h $CONVERTED_PATH/*
