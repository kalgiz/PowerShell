#!/bin/bash

echo $1
pwsh -command ". ./vsts.ps1; Invoke-PSBootstrap"
