#!/bin/bash

if [$1 == "Bootstrap"]; then
    pwsh -command ". ./vsts.ps1; Invoke-PSBootstrap"
else
    echo "Not bootstrap"
fi
