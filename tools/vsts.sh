#!/bin/bash

if [ $1 == "Bootstrap" ]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSBootstrap"
elif [ $1 == "Build" ]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSBuild"
elif [ $1 == "Test" ]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSTest"
elif [ $1 == "AfterTest" ]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSAfterTest"
elif [ $1 == "Add" ]; then
    pwsh -command "echo aaaa"
fi
