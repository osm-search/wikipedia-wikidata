#!/bin/bash

#
# Tested on Ubuntu-24
#

sudo apt-get install -y postgresql-16
sudo -u postgres createuser -s $USER

# No not significant performance increase above 250MB
sudo -u postgres mkdir -p /etc/postgresql/16/main/conf.d/
echo "
work_mem = 250MB
" | sudo -u postgres tee /etc/postgresql/16/main/conf.d/wikipedia.conf

sudo systemctl restart postgresql

sudo apt-get install -y wget coreutils nodejs jq moreutils pigz
sudo apt-get install -y python3-dev python3-pip python3-setuptools build-essential

# https://wdtaxonomy.readthedocs.io/
sudo apt-get install -y nodejs
node --version
sudo npm install -g wikidata-taxonomy
wdtaxonomy --version
