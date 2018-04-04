#!/bin/bash

if [ $1 == "Bootstrap" ]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSBootstrap"
elif [ $1 == "Build" ]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSBuild"
elif [ $1 == "Test" ]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSTest"
fi
