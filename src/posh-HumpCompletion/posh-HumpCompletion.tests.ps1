# $here = Split-Path -Parent $MyInvocation.MyCommand.Path
$global:poshhumpSkipTabCompletionInstall = $true
$global:poshhumpLoadCommandsSync = $true

$global:HumpCompletionCommandCache = $null #clear cache in case left over from installation etc!

function PoshTabExpansion2Wrapper ($line, $index = -1) {
    # Clear-HumpCompletionCommandCache
    $tokens = $null;
    if ($index -eq -1) {
        $index = $line.Length
    }
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($line, [ref]$tokens, [ref]$null)
    $result = [PoshHumpCompletion.HumpCompletion]::Instance.Complete($ast, $index)
    # ConvertTo-Json $result | Write-Host
    $result 
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Add-Type -Path "$here\bin\Release\netstandard2.0\posh-HumpCompletion.dll"
Add-Type -Path "$here\..\posh-HumpCompletion.TestHelpers\bin\Release\netstandard2.0\posh-HumpCompletion.TestHelpers.dll"

Describe "PoshHumpTabExpansion2 - command completion" {
    $helper = New-Object -TypeName "PoshHumpCompletion.TestHelpers.MockedCompletionInvoker"
    $helper.WithCommands("Get-Command", "Get-ChildItem", "Get-Content", "Set-Content", "Get-CimInstance", "Switch-AzureMode")
    It "ignores commands when no matching prefix" {
        Assert-Equivalent -Actual $helper.Complete("Foo-C").CompletionMatches -Expected $null
    }
    It "provides matches filtered to prefix" {
        Assert-Equivalent -Actual $helper.Complete("Set-C").CompletionMatches -Expected @('Set-Content') # i.e. doesn't match "Command"
    }
    It "matches multiple items (including partial matches)" {
        # TODO - want to have this ordered by exact hump match first!
        Assert-Equivalent -Actual $helper.Complete("Get-C").CompletionMatches -Expected @('Get-ChildItem', 'Get-CimInstance', 'Get-Command', 'Get-Content')
    }
    It "matches with lower-case filter refinement" {
        # TODO - want to have this ordered by exact hump match first!
        Assert-Equivalent -Actual $helper.Complete("Get-ChI").CompletionMatches -Expected @('Get-ChildItem')
    }
    It "matches multiple items - multihump (including partial matches)" {
        Assert-Equivalent -Actual $helper.Complete("Get-CI").CompletionMatches -Expected @('Get-ChildItem', 'Get-CimInstance')
    }
    It "does not complete when trailing spaces" {
        Assert-Equivalent -Actual $helper.Complete("Get-CI ").CompletionMatches | Should Be $null
    }
    It "matches case-insensitively on Verb" {
        Assert-Equivalent -Actual $helper.Complete("set-C").CompletionMatches -Expected @('Set-Content')
    }
    It "sets replacement index/length for completion of simple input" {
        $result = $helper.Complete("Set-C")
        $result.ReplacementIndex | Should Be 0
        $result.ReplacementLength | Should Be 5
    }
    It "sets replacement index/length for completion at the start of the input" {
        #                           012345678901234567890
        $result = $helper.Complete("Get-ChI | Get-Content", 7) 
        $result.ReplacementIndex | Should Be 0
        $result.ReplacementLength | Should Be 7
    }
    It "sets replacement index/length for completion at the end of the input" {
        #                          0123456789012345
        $result =$helper.Complete("Get-ChI | Get-Co", 16)
        $result.ReplacementIndex | Should Be 10
        $result.ReplacementLength | Should Be 6
    }
    It "sets replacement index/length for completion at the end of the input with parameter input" {
        #                           01234567890123456789
        $result = $helper.Complete("Get-ChI | Get-Co foo", 16)
        $result.ReplacementIndex | Should Be 10
        $result.ReplacementLength | Should Be 6
    }
}
Describe "PoshHumpTabExpansion2 - parameter completion" {
    $helper = New-Object -TypeName "PoshHumpCompletion.TestHelpers.MockedCompletionInvoker"
    $helper.WithParameters("Get-Foo1", "-TestOne", "-TestTwo", "-TestThree")
    $helper.WithParameters("Get-Help", "-Category", "-Component", "-Debug", "-Detailed", "-ErrorAction", "-ErrorVariable", "-Examples", "-Full", "-Functionality", "-InformationAction", "-InformationVariable", "-Name", "-Online", "-OutBuffer", "-OutVariable", "-Parameter", "-Path", "-PipelineVariable", "-Role", "-ShowWindow", "-Verbose", "-WarningAction", "-WarningVariable")
    It "handles simple completion" {
        Assert-Equivalent -Actual $helper.Complete("Get-Help -Fu").CompletionMatches -Expected @("-Full", "-Functionality")
    }
    It "matches with hump completion on capitals" {
        Assert-Equivalent -Actual $helper.Complete("Get-Foo1 -TT").CompletionMatches -Expected @("-TestTwo", "-TestThree")
    }
    It "matches with hump completion on capitals and lowercase" {
        Assert-Equivalent -Actual $helper.Complete("Get-Foo1 -TTw").CompletionMatches -Expected @("-TestTwo")
    }
    It "matches in the middle of the command text" {
        #                           01234567890123456
        $result = $helper.Complete("Get-Help -Fu -Bar", 12)
        $result.ReplacementIndex | Should Be 9
        $result.ReplacementLength | Should Be 3
        Assert-Equivalent -Actual $result.CompletionMatches -Expected @("-Full", "-Functionality")
    }
    It "matches with hump completion on capitals" {
        #                           0123456789012345678901234
        $result = $helper.Complete("Get-Foo1 -TT | Write-Host", 12)
        $result.ReplacementIndex | Should Be 9
        $result.ReplacementLength | Should Be 3
        Assert-Equivalent -Actual $result.CompletionMatches -Expected @("-TestTwo", "-TestThree")
    }
}
Describe "PoshHumpTabExpansion2 - variable completion" {
    $helper = New-Object -TypeName "PoshHumpCompletion.TestHelpers.MockedCompletionInvoker"
    $helper.WithVariables("poshHumpCompletionTest_TestFoo", "poshHumpCompletionTest_TestBar", "poshHumpCompletionTest_TestBaz")
    It "handles simple completion" {
        #                            012345678901234567890123456789
        $result = $helper.Complete("`$poshHumpCompletionTest_TB")
        Assert-Equivalent -Actual ($result).CompletionMatches -Expected @("`$poshHumpCompletionTest_TestBar", "`$poshHumpCompletionTest_TestBaz")
        $result.ReplacementIndex | Should Be 0
        $result.ReplacementLength | Should Be 26
    }
    It "handles completion in the middle of a statement" {
        #                           0123456789012 34567890123456789012345678
        $result = $helper.Complete("Get-Foo -Bar `$poshHumpCompletionTest_TB | Invoke-Wibble", 38)
        Assert-Equivalent -Actual ($result).CompletionMatches -Expected @("`$poshHumpCompletionTest_TestBar", "`$poshHumpCompletionTest_TestBaz")
        $result.ReplacementIndex | Should Be 13
        $result.ReplacementLength | Should Be 26
    }
}