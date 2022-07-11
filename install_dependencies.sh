#!/bin/bash

#
# Tested on Ubuntu-20
#

sudo apt-get install -y wget coreutils nodejs jq moreutils pigz

# https://github.com/wireservice/csvkit
# https://csvkit.readthedocs.io
sudo apt-get install -y python3-dev python3-pip python3-setuptools build-essential
pip install csvkit

# https://wdtaxonomy.readthedocs.io/
node --version
sudo npm install -g wikidata-taxonomy
