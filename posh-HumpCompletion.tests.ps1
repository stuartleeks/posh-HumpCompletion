$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".tests.", ".")
$global:poshhumpSkipTabCompletionInstall = $true
. "$here\$sut"

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

Describe "GetWildcardSuffixForm" {
	It "returns wildcard for null" {
		GetWildcardSuffixForm $null | Should Be "*"
	}
	It "returns wildcard for empty string" {
		GetWildcardSuffixForm "" | Should Be "*"
	}		
	It "returns multiple wildcard for multihump string" {
		GetWildcardSuffixForm "AzRV" | Should Be "Az*R*V*"
	} 
}
function PoshTabExpansion2Wrapper ($line) {
	$tokens = $null;
	$ast = [System.Management.Automation.Language.Parser]::ParseInput($line, [ref]$tokens, [ref]$null)
	(PoshHumpTabExpansion2 $ast $line.Length).CompletionMatches
}
Describe "PoshHumpTabExpansion2 - basic completion" {
	Mock Get-Command { @( 
				[PSCustomObject] @{'Name' = 'Get-Command'},
				[PSCustomObject] @{'Name' = 'Get-ChildItem'},
				[PSCustomObject] @{'Name' = 'Get-Content'},
				[PSCustomObject] @{'Name' = 'Set-Content'},
				[PSCustomObject] @{'Name' = 'Get-CimInstance'},
				[PSCustomObject] @{'Name' = 'Switch-AzureMode'}		
	)}
	It "ignores commands when no matching prefix" {
		,(PoshTabExpansion2Wrapper "Foo-C") | Should Be $null
	}
	It "provides matches filtered to prefix" {
		,(PoshTabExpansion2Wrapper "Set-C") | Should MatchArrayOrdered @('Set-Content') # i.e. doesn't match "Command"
	}
	It "matches multiple items (including partial matches)" {
		# TODO - want to have this ordered by exact hump match first!
		#,(PoshHumpTabExpansion "Get-C") | Should MatchArrayOrdered @('Get-Content', 'Get-Command', 'Get-ChildItem', 'Get-CimInstance')
		,(PoshTabExpansion2Wrapper "Get-C") | Should MatchArrayOrdered @('Get-ChildItem', 'Get-CimInstance', 'Get-Command', 'Get-Content')
	}
	It "matches with lower-case filter" {
		# TODO - want to have this ordered by exact hump match first!
		#,(PoshHumpTabExpansion "Get-C") | Should MatchArrayOrdered @('Get-Content', 'Get-Command', 'Get-ChildItem', 'Get-CimInstance')
		,(PoshTabExpansion2Wrapper "Get-ChI") | Should MatchArrayOrdered @('Get-ChildItem')
	}
	It "matches multiple items - multihump (including partial matches)" {
		,(PoshTabExpansion2Wrapper "Get-CI") | Should MatchArrayOrdered @('Get-ChildItem', 'Get-CimInstance')
	}
	It "does not complete when trailing spaces" {
		,(PoshTabExpansion2Wrapper "Get-CI ") | Should Be $null
	}
}

# TODO
#  * add tests for complation of parameter names
#  * add tests for completion in the middle of a string
#  * add tests for completion of variable names