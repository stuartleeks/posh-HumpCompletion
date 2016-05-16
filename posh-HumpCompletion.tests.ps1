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
function PoshTabExpansion2Wrapper ($line, $index = -1) {
	$tokens = $null;
	if ($index -eq -1) {
		$index = $line.Length
	}
	$ast = [System.Management.Automation.Language.Parser]::ParseInput($line, [ref]$tokens, [ref]$null)
	PoshHumpTabExpansion2 $ast $index
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
		,(PoshTabExpansion2Wrapper "Foo-C").CompletionMatches | Should Be $null
	}
	It "provides matches filtered to prefix" {
		,(PoshTabExpansion2Wrapper "Set-C").CompletionMatches | Should MatchArrayOrdered @('Set-Content') # i.e. doesn't match "Command"
	}
	It "matches multiple items (including partial matches)" {
		# TODO - want to have this ordered by exact hump match first!
		#,(PoshHumpTabExpansion "Get-C") | Should MatchArrayOrdered @('Get-Content', 'Get-Command', 'Get-ChildItem', 'Get-CimInstance')
		,(PoshTabExpansion2Wrapper "Get-C").CompletionMatches | Should MatchArrayOrdered @('Get-ChildItem', 'Get-CimInstance', 'Get-Command', 'Get-Content')
	}
	It "matches with lower-case filter" {
		# TODO - want to have this ordered by exact hump match first!
		#,(PoshHumpTabExpansion "Get-C") | Should MatchArrayOrdered @('Get-Content', 'Get-Command', 'Get-ChildItem', 'Get-CimInstance')
		,(PoshTabExpansion2Wrapper "Get-ChI").CompletionMatches | Should MatchArrayOrdered @('Get-ChildItem')
	}
	It "matches multiple items - multihump (including partial matches)" {
		,(PoshTabExpansion2Wrapper "Get-CI").CompletionMatches | Should MatchArrayOrdered @('Get-ChildItem', 'Get-CimInstance')
	}
	It "does not complete when trailing spaces" {
		,(PoshTabExpansion2Wrapper "Get-CI ").CompletionMatches | Should Be $null
	}
	It "sets replacement index/length for completion of simple input" {
		$result = PoshTabExpansion2Wrapper "Set-C"
		$result.ReplacementIndex | Should Be 0
		$result.ReplacementLength | Should Be 5
	}
	It "sets replacement index/length for completion at the start of the input" {
		$result = PoshTabExpansion2Wrapper "Get-ChI | Get-Content" 7 
		$result.ReplacementIndex | Should Be 0
		$result.ReplacementLength | Should Be 7
	}
	It "sets replacement index/length for completion at the end of the input" {
		$result = PoshTabExpansion2Wrapper "Get-ChI | Get-Co" 
		$result.ReplacementIndex | Should Be 10
		$result.ReplacementLength | Should Be 6
	}
}

# TODO
#  * add tests for complation of parameter names
#  * add tests for completion in the middle of a string
#  * add tests for completion of variable names