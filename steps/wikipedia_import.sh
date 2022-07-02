#!/bin/bash

# set defaults
: ${BUILDID:=latest}
: ${DATABASE_NAME:=wikiprocessingdb}
: ${LANGUAGES:=bar,cy}
LANGUAGES_ARRAY=($(echo $LANGUAGES | tr ',' ' '))

DOWNLOADED_PATH="$BUILDID/downloaded"

psqlcmd() {
     psql --quiet $DATABASE_NAME |& \
     grep -v 'does not exist, skipping' |& \
     grep -v 'violates check constraint' |& \
     grep -vi 'Failing row contains'
}

mysql2pgsqlcmd() {
     ./bin/mysql2pgsql.perl --nodrop /dev/stdin /dev/stdout
}









echo "====================================================================="
echo "Import individual wikipedia language tables"
echo "====================================================================="

for LANG in "${LANGUAGES_ARRAY[@]}"
do
    echo "Import language: $LANG"


    # We pre-create the table schema. This allows us to
    # 1. Skip index creation. Most queries we do are full table scans
    # 2. Add constrain to only import namespace=0 (wikipedia articles)
    # Both cuts down data size considerably (50%+)


    ##
    ## PAGELINKS
    ##
    FILENAME="$DOWNLOADED_PATH/$LANG/pagelinks.sql.gz"
    TABLENAME="${LANG}pagelinks"

    echo "Importing $FILENAME"

    echo "DROP TABLE IF EXISTS ${TABLENAME};" | psqlcmd
    echo "CREATE TABLE ${TABLENAME} (
       pl_from            int  NOT NULL DEFAULT '0',
       pl_namespace       int  NOT NULL DEFAULT '0',
       pl_title           text NOT NULL DEFAULT '',
       pl_from_namespace  int  NOT NULL DEFAULT '0'
    );" | psqlcmd

    time \
      gzip -dc ${FILENAME} | \
      sed "s/\`pagelinks\`/\`${TABLENAME}\`/g" | \
      mysql2pgsqlcmd | \
      grep -v '^CREATE INDEX ' | \
      psqlcmd


    ##
    ## PAGE
    ##
    FILENAME="$DOWNLOADED_PATH/$LANG/page.sql.gz"
    TABLENAME="${LANG}page"

    echo "Importing $FILENAME"

    # autoincrement serial8 4byte
    echo "DROP TABLE IF EXISTS ${TABLENAME};" | psqlcmd
    echo "CREATE TABLE ${TABLENAME} (
       page_id             int NOT NULL,
       page_namespace      int NOT NULL DEFAULT '0',
       page_title          text NOT NULL DEFAULT '',
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
      gzip -dc ${FILENAME} | \
      sed "s/\`page\`/\`${TABLENAME}\`/g" | \
      mysql2pgsqlcmd | \
      grep -v '^CREATE INDEX ' | \
      psqlcmd



    ##
    ## LANGLINKS
    ##
    FILENAME="$DOWNLOADED_PATH/$LANG/langlinks.sql.gz"
    TABLENAME="${LANG}langlinks"

    echo "Importing $FILENAME"

    echo "DROP TABLE IF EXISTS ${TABLENAME};" | psqlcmd
    echo "CREATE TABLE ${TABLENAME} (
       ll_from   int  NOT NULL DEFAULT '0',
       ll_lang   text NOT NULL DEFAULT '',
       ll_title  text NOT NULL DEFAULT ''
    );" | psqlcmd

    time \
      gzip -dc ${FILENAME} | \
      sed "s/\`langlinks\`/\`${TABLENAME}\`/g" | \
      mysql2pgsqlcmd | \
      grep -v '^CREATE INDEX ' | \
      psqlcmd



    ##
    ## REDIRECT
    ##
    FILENAME="$DOWNLOADED_PATH/$LANG/redirect.sql.gz"
    TABLENAME="${LANG}redirect"

    echo "Importing $FILENAME"

    echo "DROP TABLE IF EXISTS ${TABLENAME};" | psqlcmd
    echo "CREATE TABLE ${TABLENAME} (
       rd_from       int   NOT NULL DEFAULT '0',
       rd_namespace  int   NOT NULL DEFAULT '0',
       rd_title      text  NOT NULL DEFAULT '',
       rd_interwiki  text  DEFAULT NULL,
       rd_fragment   text  DEFAULT NULL
    );" | psqlcmd

    time \
      gzip -dc ${FILENAME} | \
      sed "s/\`redirect\`/\`${TABLENAME}\`/g" | \
      mysql2pgsqlcmd | \
      grep -v '^CREATE INDEX ' | \
      psqlcmd
done



