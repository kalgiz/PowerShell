#!/bin/bash
# Install dependencies and clean up
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        locales\
    && rm -rf /var/lib/apt/lists/*

# Setup the locale
ENV LANG en_US.UTF-8
ENV LC_ALL $LANG
RUN locale-gen $LANG && update-locale

./install-powershell.sh
nvm install 6.4.0
npm install -g markdown-spellcheck@0.11.0;
