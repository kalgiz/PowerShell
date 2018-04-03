$repoRoot = Join-Path $PSScriptRoot '..'
Import-Module (Join-Path $repoRoot 'build.psm1') -Scope Global
$isPR = $env:BUILD_REASON -eq "PullRequest"
$commitMessage = git log --format=%B -n 1 $env:BUILD_SOURCEVERSION
$hasFeatureTag = $commitMessage -match '\[feature\]'
$hasPackageTag = $commitMessage -match '\[package\]'
$hasRunFailingTestTag = $commitMessage -match '\[includeFailingTest\]'
$isDailyBuild = $env:BUILD_REASON -eq 'Schedule'
$isFullBuild = $isDailyBuild -or $hasFeatureTag

function Get-ReleaseTag
{
    $metaDataPath = Join-Path -Path $PSScriptRoot -ChildPath 'metadata.json'
    $metaData = Get-Content $metaDataPath | ConvertFrom-Json

    $releaseTag = $metadata.NextReleaseTag
    # if($env:BUILD_BUILDNUMBER)
    # {
    #     Write-Host $env:BUILD_BUILDNUMBER
    #     $releaseTag = $releaseTag.split('.')[0..2] -join '.'
    #     $releaseTag = $releaseTag+'.'+$env:BUILD_BUILDNUMBER
    # }

    return $releaseTag
}

function Invoke-PSBootstrap {
    Write-Host -Foreground Green "Executing Linux vsts -BootStrap `$isPR='$isPr' - $commitMessage"
    # Make sure we have all the tags
    Sync-PSTags -AddRemoteIfMissing
    Start-PSBootstrap
}

function Invoke-PSBuild {
    $releaseTag = Get-ReleaseTag
    Write-Host $releaseTag

    Write-Host -Foreground Green "Executing Linux vsts `$isPR='$isPr' `$isFullBuild='$isFullBuild' - $commitMessage"
    $output = Split-Path -Parent (Get-PSOutput -Options (New-PSOptions))

    $originalProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        ## We use CrossGen build to run tests only if it's the daily build.
        Start-PSBuild -CrossGen -PSModuleRestore -CI -ReleaseTag $releaseTag
    }
    finally{
        $ProgressPreference = $originalProgressPreference
    }

    $testResultsNoSudo = "$pwd/TestResultsNoSudo.xml"
    $testResultsSudo = "$pwd/TestResultsSudo.xml"

    $pesterParam = @{
        'binDir'     = $output
        'PassThru'   = $true
        'Terse'      = $true
        'Tag'        = @()
        'ExcludeTag' = @('RequireSudoOnUnix')
        'OutputFile' = $testResultsNoSudo
    }

    if ($isFullBuild) {
        $pesterParam['Tag'] = @('CI','Feature','Scenario')
    } else {
        $pesterParam['Tag'] = @('CI')
        # $pesterParam['ThrowOnFailure'] = $true
    }

    if ($hasRunFailingTestTag)
    {
        $pesterParam['IncludeFailingTest'] = $true
    }

    # Remove telemetry semaphore file in CI
    $telemetrySemaphoreFilepath = Join-Path $output DELETE_ME_TO_DISABLE_CONSOLEHOST_TELEMETRY
    if ( Test-Path "${telemetrySemaphoreFilepath}" ) {
        Remove-Item -force ${telemetrySemaphoreFilepath}
    }

    # Running tests which do not require sudo.
    # Start-PSPester @pesterParam -Path "$repoRoot/test/powershell/Modules/Microsoft.PowerShell.Management/Get-Process.Tests.ps1"
    $pesterPassThruNoSudoObject = Start-PSPester @pesterParam

    #  # Running tests, which require sudo.
    #  $pesterParam['Tag'] = @('RequireSudoOnUnix')
    #  $pesterParam['ExcludeTag'] = @()
    #  $pesterParam['Sudo'] = $true
    #  $pesterParam['OutputFile'] = $testResultsSudo
    #  $pesterPassThruSudoObject = Start-PSPester @pesterParam

    #  # Determine whether the build passed
    #  try {
    #      # this throws if there was an error
    #      @($pesterPassThruNoSudoObject, $pesterPassThruSudoObject) | ForEach-Object { Test-PSPesterResults -ResultObject $_ }
    #      $result = "PASS"
    #  }
    #  catch {
    #      $resultError = $_
    #      $result = "FAIL"
    #  }

    #  try {
    #      $SequentialXUnitTestResultsFile = "$pwd/SequentialXUnitTestResults.xml"
    #      $ParallelXUnitTestResultsFile = "$pwd/ParallelXUnitTestResults.xml"

    #      Start-PSxUnit -SequentialTestResultsFile $SequentialXUnitTestResultsFile -ParallelTestResultsFile $ParallelXUnitTestResultsFile
    #      # If there are failures, Test-XUnitTestResults throws
    #      $SequentialXUnitTestResultsFile, $ParallelXUnitTestResultsFile | ForEach-Object { Test-XUnitTestResults -TestResultsFile $_ }
    #  }
    #  catch {
    #      $result = "FAIL"
    #      if (!$resultError)
    #      {
    #          $resultError = $_
    #      }
    #  }
}

