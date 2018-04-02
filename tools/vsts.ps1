Write-Host "Hooray bootstrap"
Invoke-PSBootstrap

function Invoke-PSBootstrap {
    Write-Host "Invoke-PSBootstrap function called"
    # Write-Host -Foreground Green "Executing Linux vsts -BootStrap"
    # Write-Host -Foreground Green "Executing Linux vsts -BootStrap `$isPR='$isPr' - $commitMessage"
    # Make sure we have all the tags
    # Sync-PSTags -AddRemoteIfMissing
    # Start-PSBootstrap
}
