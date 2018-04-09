$repoRoot = Join-Path $PSScriptRoot '..'
Import-Module (Join-Path $repoRoot 'build.psm1') -Scope Global
$isPR = $env:BUILD_REASON -eq "PullRequest"
$commitMessage = git log --format=%B -n 1 $env:BUILD_SOURCEVERSION
$hasFeatureTag = $commitMessage -match '\[feature\]'
$hasPackageTag = $commitMessage -match '\[package\]'
$createPackages = -not $isPr -or $hasPackageTag
$hasRunFailingTestTag = $commitMessage -match '\[includeFailingTest\]'
$isDailyBuild = $env:BUILD_REASON -eq 'Schedule'
$isFullBuild = $isDailyBuild -or $hasFeatureTag

function Get-ReleaseTag
{
    $metaDataPath = Join-Path -Path $PSScriptRoot -ChildPath 'metadata.json'
    $metaData = Get-Content $metaDataPath | ConvertFrom-Json

    $releaseTag = $metadata.NextReleaseTag
    if($env:BUILD_BUILDNUMBER)
    {
        $releaseTag = $releaseTag.split('.')[0..2] -join '.'
        # If the Build number has a dot in it, only the string before dot is inserted into releaseTag.
        $buildMajorNumber = $env:BUILD_BUILDNUMBER
        $dotPos = $buildMajorNumber.IndexOf(".")
        if ($dotPos -ne -1) {
            $buildMajorNumber = $buildMajorNumber.Substring(0, $dotPos)
        }
        $releaseTag = $releaseTag+'.'+$buildMajorNumber
    }

    return $releaseTag
}

function Invoke-PSBootstrap {
    Write-Host -Foreground Green "Executing Linux vsts -BootStrap `$isPR='$isPr' - $commitMessage"
    # Make sure we have all the tags
    Sync-PSTags -AddRemoteIfMissing
    Start-PSBootstrap -Package:$createPackages
    Write-Host "Version table!!!!"
    Write-Host $PSVersionTable
    Write-Host $PSHOME
}

function Invoke-PSBuild {
    $releaseTag = Get-ReleaseTag

    Write-Host -Foreground Green "Executing Linux vsts `$isPR='$isPr' `$isFullBuild='$isFullBuild' - $commitMessage"
    $originalProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Start-PSBuild -CrossGen -PSModuleRestore -CI -ReleaseTag $releaseTag
    }
    finally{
        $ProgressPreference = $originalProgressPreference
    }
    Write-Host "Version table!!!!"
    Write-Host $PSVersionTable
    Write-Host $PSHOME
}

function Invoke-PSTest {
    Write-Host "Version table!!!!"
    Write-Host $PSVersionTable
    Write-Host $PSHOME
    Write-Host $pwd

    $testResultsNoSudo = "$pwd/TestResultsNoSudo.xml"
    $testResultsSudo = "$pwd/TestResultsSudo.xml"
    $output = Split-Path -Parent (Get-PSOutput -Options (New-PSOptions))

    $pesterParam = @{
        'binDir'         = $output
        'PassThru'       = $true
        'Terse'          = $true
        'Tag'            = @()
        'ExcludeTag'     = @('RequireSudoOnUnix')
        'OutputFile'     = $testResultsNoSudo
        'ThrowOnFailure' = $true
    }

    if ($isFullBuild) {
        $pesterParam['Tag'] = @('CI','Feature','Scenario')
    } else {
        $pesterParam['Tag'] = @('CI')
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
    $pesterPassThruNoSudoObject = Start-PSPester @pesterParam

    # Running tests, which require sudo.
    $pesterParam['Tag'] = @('RequireSudoOnUnix')
    $pesterParam['ExcludeTag'] = @()
    $pesterParam['Sudo'] = $true
    $pesterParam['OutputFile'] = $testResultsSudo
    $pesterPassThruSudoObject = Start-PSPester @pesterParam

    # Determine whether the build passed
    try {
        # this throws if there was an error
        @($pesterPassThruNoSudoObject, $pesterPassThruSudoObject) | ForEach-Object { Test-PSPesterResults -ResultObject $_ }
        $result = "PASS"
    }
    catch {
        $resultError = $_
        $result = "FAIL"
    }

    try {
        $SequentialXUnitTestResultsFile = "$pwd/SequentialXUnitTestResults.xml"
        $ParallelXUnitTestResultsFile = "$pwd/ParallelXUnitTestResults.xml"

        Start-PSxUnit -SequentialTestResultsFile $SequentialXUnitTestResultsFile -ParallelTestResultsFile $ParallelXUnitTestResultsFile
        # If there are failures, Test-XUnitTestResults throws
        $SequentialXUnitTestResultsFile, $ParallelXUnitTestResultsFile | ForEach-Object { Test-XUnitTestResults -TestResultsFile $_ }
    }
    catch {
        $result = "FAIL"
        if (!$resultError)
        {
            $resultError = $_
        }
    }
}

function Invoke-PSAfterTest {
    Write-Host $env:AGENT_JOBSTATUS
}
