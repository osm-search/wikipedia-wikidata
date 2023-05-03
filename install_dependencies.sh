#!/bin/bash

#
# Tested on Ubuntu-22
#

sudo apt-get install -y postgresql-14
sudo -u postgres createuser -s $USER

# The database can be 100GB or more. If you want to create it on a separate
# drive you can try:
#
# sudo -u postgres psql -c 'SELECT * FROM pg_tablespace;'
# # oid  |  spcname   | spcowner | spcacl | spcoptions
# #------+------------+----------+--------+------------
# # 1663 | pg_default |       10 |        |
# # 1664 | pg_global  |       10 |        |
#
# EXTRASPACE_PATH=/mnt/HC_Volume_21300566/postgres-data
# sudo mkdir -p $EXTRASPACE_PATH
# sudo chown postgres $EXTRASPACE_PATH
# sudo chgrp postgres $EXTRASPACE_PATH
#
# sudo -u postgres psql -c "CREATE TABLESPACE extraspace LOCATION '$EXTRASPACE_PATH';"
# sudo -u postgres psql -c 'SELECT * FROM pg_tablespace;'



sudo apt-get install -y wget coreutils nodejs jq moreutils pigz

# https://github.com/wireservice/csvkit
# https://csvkit.readthedocs.io
sudo apt-get install -y python3-dev python3-pip python3-setuptools build-essential
pip install csvkit
sudo ln -s ~/.local/bin/csvcut /usr/local/bin/csvcut

# https://wdtaxonomy.readthedocs.io/
sudo apt-get install -y nodejs
node --version
sudo npm install -g wikidata-taxonomy
wdtaxonomy --version
