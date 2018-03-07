# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
Describe "New-EventLog cmdlet tests" -Tags @('CI', 'RequireAdminOnWindows') {

    BeforeAll {
        $defaultParamValues = $PSdefaultParameterValues.Clone()
        $IsNotSkipped = ($IsWindows -and !$IsCoreCLR)
        $PSDefaultParameterValues["it:skip"] = !$IsNotSkipped
    }

    AfterAll {
        $global:PSDefaultParameterValues = $defaultParamValues
    }

    BeforeEach {
        if ($IsNotSkipped) {
            Remove-EventLog -LogName TestLog -ea Ignore
            {New-EventLog -LogName TestLog -Source TestSource -ErrorAction Stop}                              | Should -Not -Throw
            {Write-EventLog -LogName TestLog -Source TestSource -Message "Test" -EventID 1 -ErrorAction Stop} | Should -Not -Throw
        }
    }
    #CmdLet is NYI - change to -Skip:($NonWinAdmin) when implemented
    It "should be able to Remove-EventLog -LogName <string> -ComputerName <string>" -Pending:($True) {
      {Remove-EventLog -LogName TestLog -ComputerName $env:COMPUTERNAME -ErrorAction Stop}              | Should -Not -Throw
      try {Write-EventLog -LogName TestLog -Source TestSource -Message "Test" -EventID 1 -ErrorAction Stop; Throw "Previous statement unexpectedly succeeded..."
      } catch {$_.FullyQualifiedErrorId             | Should -Be "Microsoft.PowerShell.Commands.WriteEventLogCommand"}
      try {Get-EventLog -LogName TestLog -ErrorAction Stop; Throw "Previous statement unexpectedly succeeded..."
      } catch {$_.FullyQualifiedErrorId             | Should -Be "System.InvalidOperationException,Microsoft.PowerShell.Commands.GetEventLogCommand"}
    }
    #CmdLet is NYI - change to -Skip:($NonWinAdmin) when implemented
    It "should be able to Remove-EventLog -Source <string> -ComputerName <string>"  -Pending:($True) {
      {Remove-EventLog -Source TestSource -ComputerName $env:COMPUTERNAME -ErrorAction Stop} | Should -Not -Throw
      try {Write-EventLog -LogName TestLog -Source TestSource -Message "Test" -EventID 1 -ErrorAction Stop; Throw "Previous statement unexpectedly succeeded..."
      } catch {$_.FullyQualifiedErrorId             | Should -Be "Microsoft.PowerShell.Commands.WriteEventLogCommand"}
      try {Get-EventLog -LogName TestLog -ErrorAction Stop; Throw "Previous statement unexpectedly succeeded..."
      } catch {$_.FullyQualifiedErrorId             | Should -Be "System.InvalidOperationException,Microsoft.PowerShell.Commands.GetEventLogCommand"}
    }
}
