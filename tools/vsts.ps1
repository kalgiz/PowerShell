$repoRoot = Join-Path $PSScriptRoot '..'
Import-Module (Join-Path $repoRoot 'build.psm1') -Scope Global

function Invoke-PSBootstrap {
    Write-Host "Invoke-PSBootstrap function called"
    Write-Host -Foreground Green "Executing Linux vsts -BootStrap"
    # Write-Host -Foreground Green "Executing Linux vsts -BootStrap `$isPR='$isPr' - $commitMessage"
    # Make sure we have all the tags
    Sync-PSTags -AddRemoteIfMissing
    Start-PSBootstrap
}

Write-Host "Hooray bootstrap"
