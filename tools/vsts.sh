#!/bin/bash

if [ $1 == "Bootstrap" ]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSBootstrap"
if [ $1 == "Build" ]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSBuild"
fi
