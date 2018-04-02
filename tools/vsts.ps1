$repoRoot = Join-Path $PSScriptRoot '..'
Import-Module (Join-Path $repoRoot 'build.psm1') -Scope Global
$isPR = $env:BUILD_REASON -eq "PullRequest"
$commitMessage = git log --format=%B -n 1 $env:BUILD_SOURCEVERSION

function Invoke-PSBootstrap {
    Write-Host -Foreground Green "Executing Linux vsts -BootStrap `$isPR='$isPr' - $commitMessage"
    # Make sure we have all the tags
    Sync-PSTags -AddRemoteIfMissing
    Start-PSBootstrap
}

