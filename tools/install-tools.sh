#!/bin/bash
# Install dependencies and clean up

./install-powershell.sh
nvm install 6.4.0
npm install -g markdown-spellcheck@0.11.0;
apt-get install less
