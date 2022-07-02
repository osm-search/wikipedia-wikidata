#!/bin/bash

psqlcmd() {
     psql --quiet wikiprocessingdb |& \
     grep -v 'does not exist, skipping' |& \
     grep -v 'violates check constraint' |& \
     grep -vi 'Failing row contains'
}

mysql2pgsqlcmd() {
     ./bin/mysql2pgsql.perl --nodrop /dev/stdin /dev/stdout
}


# languages to process (refer to List of Wikipedias here: https://en.wikipedia.org/wiki/List_of_Wikipedias)
# requires Bash 4.0
readarray -t LANGUAGES < languages.txt



echo "====================================================================="
echo "Create wikipedia calculation tables"
echo "====================================================================="

echo "CREATE TABLE linkcounts (
        language text,
        title    text,
        count    integer,
        sumcount integer,
        lat      double precision,
        lon      double precision
     );"  | psqlcmd

echo "CREATE TABLE wikipedia_article (
        language    text NOT NULL,
        title       text NOT NULL,
        langcount   integer,
        othercount  integer,
        totalcount  integer,
        lat double  precision,
        lon double  precision,
        importance  double precision,
        title_en    text,
        osm_type    character(1),
        osm_id      bigint
      );" | psqlcmd

echo "CREATE TABLE wikipedia_redirect (
        language   text,
        from_title text,
        to_title   text
     );" | psqlcmd






echo "====================================================================="
echo "Import individual wikipedia language tables"
echo "====================================================================="

for i in "${LANGUAGES[@]}"
do
    echo "Language: $i"

    # We pre-create the table schema. This allows us to
    # 1. Skip index creation. Most queries we do are full table scans
    # 2. Add constrain to only import namespace=0 (wikipedia articles)
    # Both cuts down data size considerably (50%+)

    echo "Importing ${i}wiki-latest-pagelinks"

    echo "DROP TABLE IF EXISTS ${i}pagelinks;" | psqlcmd
    echo "CREATE TABLE ${i}pagelinks (
       pl_from            int  NOT NULL DEFAULT '0',
       pl_namespace       int  NOT NULL DEFAULT '0',
       pl_title           text NOT NULL DEFAULT '',
       pl_from_namespace  int  NOT NULL DEFAULT '0'
    );" | psqlcmd

    time \
      gzip -dc ${i}wiki-latest-pagelinks.sql.gz | \
      sed "s/\`pagelinks\`/\`${i}pagelinks\`/g" | \
      mysql2pgsqlcmd | \
      grep -v '^CREATE INDEX ' | \
      psqlcmd




    echo "Importing ${i}wiki-latest-page"

    # autoincrement serial8 4byte
    echo "DROP TABLE IF EXISTS ${i}page;" | psqlcmd
    echo "CREATE TABLE ${i}page (
       page_id             int NOT NULL,
       page_namespace      int NOT NULL DEFAULT '0',
       page_title          text NOT NULL DEFAULT '',
       page_restrictions   text NOT NULL,
       page_is_redirect    smallint NOT NULL DEFAULT '0',
       page_is_new         smallint NOT NULL DEFAULT '0',
       page_random         double precision NOT NULL DEFAULT '0',
       page_touched        text NOT NULL DEFAULT '',
       page_links_updated  text DEFAULT NULL,
       page_latest         int NOT NULL DEFAULT '0',
       page_len            int NOT NULL DEFAULT '0',
       page_content_model  text DEFAULT NULL,
       page_lang           text DEFAULT NULL
     );" | psqlcmd

    time \
      gzip -dc ${i}wiki-latest-page.sql.gz | \
      sed "s/\`page\`/\`${i}page\`/g" | \
      mysql2pgsqlcmd | \
      grep -v '^CREATE INDEX ' | \
      psqlcmd




    echo "Importing ${i}wiki-latest-langlinks"

    echo "DROP TABLE IF EXISTS ${i}langlinks;" | psqlcmd
    echo "CREATE TABLE ${i}langlinks (
       ll_from   int  NOT NULL DEFAULT '0',
       ll_lang   text NOT NULL DEFAULT '',
       ll_title  text NOT NULL DEFAULT ''
    );" | psqlcmd

    time \
      gzip -dc ${i}wiki-latest-langlinks.sql.gz | \
      sed "s/\`langlinks\`/\`${i}langlinks\`/g" | \
      mysql2pgsqlcmd | \
      grep -v '^CREATE INDEX ' | \
      psqlcmd





    echo "Importing ${i}wiki-latest-redirect"

    echo "DROP TABLE IF EXISTS ${i}redirect;" | psqlcmd
    echo "CREATE TABLE ${i}redirect (
       rd_from       int   NOT NULL DEFAULT '0',
       rd_namespace  int   NOT NULL DEFAULT '0',
       rd_title      text  NOT NULL DEFAULT '',
       rd_interwiki  text  DEFAULT NULL,
       rd_fragment   text  DEFAULT NULL
    );" | psqlcmd

    time \
      gzip -dc ${i}wiki-latest-redirect.sql.gz | \
      sed "s/\`redirect\`/\`${i}redirect\`/g" | \
      mysql2pgsqlcmd | \
      grep -v '^CREATE INDEX ' | \
      psqlcmd
done



