#!/bin/bash

# originally it was installed only for linux
nvm install 6.4.0 &&
npm install -g markdown-spellcheck@0.11.0;

pwsh -command "./vsts.ps1"
