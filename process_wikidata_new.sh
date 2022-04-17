#!/bin/bash




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

# globe = earth, primary = 1

zcat wikidata/wikidatawiki-latest-geo_tags.sql.gz | \
python3 bin/mysqldump_to_csv.py | \
sed 's/\x0//g' | \
sed 's/\r\?//g' | \
grep ',earth,1,' | \
csvcut -c 2,5,6 | \
bin/round_coordinates.py | \
gzip -9 \
> wikidata/wikidatawiki-latest-geo_tags.csv.gz

# input
#   # 134M (690MB uncompressed)
# output
#   8.4m entries
#   89MB compressed, 240MB uncompressed
# 4175,43.1924,-81.3158
# 4180,-26.0,121.0
# 4181,43.08333333,2.41666667
# 4187,51.76055556,14.33416667

###################################################################################

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

zcat wikidata/wikidatawiki-latest-page.sql.gz | \
python3 bin/mysqldump_to_csv.py | \
sed 's/\x0//g' | \
sed 's/\r\?//g' | \
csvcut -c 1,3,2 | \
grep -e ',0$' | \
sed 's/,0$//' | \
gzip -9 \
> wikidata/wikidatawiki-latest-page.csv.gz
# 34min
# Input
#   2.8GB, (3.1GB uncompresseed)
# Output
#   480MB, 1.8GB uncompressed, about 100m lines
# page_id, title
#
# 12991,Q11474
# 12992,Q11475
# 12993,Q11476
# 12994,Introduction/sk
# 12995,Q11477
# 12996,Q11478
# 12997,Q11479
# TODO: remove those not starting with Q?

###################################################################################

# CREATE TABLE `wb_items_per_site` (
#   `ips_row_id`    bigint(20) unsigned NOT NULL AUTO_INCREMENT,
#   `ips_item_id`   int(10) unsigned    NOT NULL,
#   `ips_site_id`   varbinary(32)       NOT NULL,
#   `ips_site_page` varbinary(310)      NOT NULL,

# Only considering languages we need, cuts down 80m lines to 52m
LISTLANG=${LANGUAGES[@]}
# ar bg ca cs da de en es
LANG_E_REGEX=",\(${LISTLANG// /\\|}\),"
# ,\(ar\|bg\|ca\|cs\|da\|de\|en...\)wiki,

zcat wikidata/wikidatawiki-latest-wb_items_per_site.sql.gz | \
python3 bin/mysqldump_to_csv.py | \
sed 's/\x0//g' | \
sed 's/\r\?//g' | \
grep -e "$LANG_E_REGEX" | \
csvcut -c 2,3,4 | \
gzip -9 \
> wikidata/wikidatawiki-latest-wb_items_per_site.csv.gz
#
# Input
#   1.4GB compressed, 4.7GB uncompressed
# Output 
#   750MB compressed, 2.2GB uncompressed, 52m lines
#
# 576947,cawiki,Bryaninops amplus
# 2739322,cawiki,Bryneich
# 2927288,cawiki,Bréjaude
# 2912549,cawiki,Brúixola Brunton


