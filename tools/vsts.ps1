$repoRoot = Join-Path $PSScriptRoot '..'
Import-Module (Join-Path $repoRoot 'build.psm1') -Scope Global
$isPR = $env:BUILD_REASON -eq "PullRequest"
$commitMessage = git log --format=%B -n 1 $env:BUILD_SOURCEVERSION

function Get-ReleaseTag
{
    $metaDataPath = Join-Path -Path $PSScriptRoot -ChildPath 'metadata.json'
    $metaData = Get-Content $metaDataPath | ConvertFrom-Json

    #!!!!!!
    Write-Host $metaData

    $releaseTag = $metadata.NextReleaseTag

    #!!!!!!!
    Write-Host $env:BUILD_BUILDNUMBER

    if($env:BUILD_BUILDNUMBER)
    {
        $releaseTag = $releaseTag.split('.')[0..2] -join '.'
        $releaseTag = $releaseTag+'.'+$env:BUILD_BUILDNUMBER
    }

    #!!!!
    Write-Host $releaseTag

    return $releaseTag
}

function Ivoke-PSBuild {
    $releaseTag = Get-ReleaseTag

    #!!!!
    Write-Host $releaseTag
}

function Invoke-PSBootstrap {
    Write-Host -Foreground Green "Executing Linux vsts -BootStrap `$isPR='$isPr' - $commitMessage"
    # Make sure we have all the tags
    Sync-PSTags -AddRemoteIfMissing
    Start-PSBootstrap
}



