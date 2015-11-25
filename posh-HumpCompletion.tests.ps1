$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".tests.", ".")
. "$here\$sut"

Import-Module "$here\PesterMatchArray.psm1" -Force

$global:HumpCompletionCommandCache=$null #clear cache in case left over from installation etc!

Describe "GetCommandWithVerbAndHumpSuffix" {
	It "handles single hump" {
		$result = GetCommandWithVerbAndHumpSuffix "Get-Command"
		($result.Verb) | Should Be 'Get'
		($result.SuffixHumpForm) | Should Be 'C'
	}
	It "handles multiple humps" {
		$result = GetCommandWithVerbAndHumpSuffix "Get-ChildItem"
		($result.Verb) | Should Be 'Get'
		($result.SuffixHumpForm) | Should Be 'CI'
	}
}


Describe "PoshHumpTabExpansion" {
	Mock Get-Command { @( 
				[PSCustomObject] @{'Name' = 'Get-Command'},
				[PSCustomObject] @{'Name' = 'Get-ChildItem'},
				[PSCustomObject] @{'Name' = 'Get-Content'},
				[PSCustomObject] @{'Name' = 'Set-Content'},
				[PSCustomObject] @{'Name' = 'Get-CimInstance'},
				[PSCustomObject] @{'Name' = 'Switch-AzureMode'}		
	)}
	It "ignores commands when no matching prefix" {
		,(PoshHumpTabExpansion "Foo-C") | Should Be $null
	}
	It "provides matches filtered to prefix" {
		,(PoshHumpTabExpansion "Set-C") | Should MatchArray @('Set-Content') # i.e. doesn't match "Command"
	}
	It "matches multiple items (including partial matches)" {
		,(PoshHumpTabExpansion "Get-C") | Should MatchArray @('Get-Content', 'Get-Command', 'Get-ChildItem', 'Get-CimInstance')
	}
	It "matches multiple items - multihump (including partial matches)" {
		,(PoshHumpTabExpansion "Get-CI") | Should MatchArray @('Get-ChildItem', 'Get-CimInstance')
	}
}
