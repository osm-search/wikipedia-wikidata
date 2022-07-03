#!/bin/bash

#
# Tested on Ubuntu-20
#

sudo apt-get install -y wget perl coreutils

# https://github.com/wireservice/csvkit
# https://csvkit.readthedocs.io
sudo apt-get install -y python3-dev python3-pip python3-setuptools build-essential
pip install csvkit