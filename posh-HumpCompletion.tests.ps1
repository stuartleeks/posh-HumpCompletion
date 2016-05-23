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

Describe "GetWildcardForm" {
	It "returns wildcard for null" {
		GetWildcardForm $null | Should Be "*"
	}
	It "returns wildcard for empty string" {
		GetWildcardForm "" | Should Be "*"
	}		
	It "returns multiple wildcard for multihump string" {
		GetWildcardForm "AzRV" | Should Be "Az*R*V*"
	}
	It "ignores leading dash in parameter names" {
		GetWildcardForm "-ABC" | Should Be "-A*B*C*"
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
Describe "PoshHumpTabExpansion2 - command completion" {
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
	It "matches with lower-case filter refinement" {
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
	It "matches case-insensitively on Verb" {
		,(PoshTabExpansion2Wrapper "set-C").CompletionMatches | Should MatchArrayOrdered @('Set-Content')
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
		$result = PoshTabExpansion2Wrapper "Get-ChI | Get-Co" 16
		$result.ReplacementIndex | Should Be 10
		$result.ReplacementLength | Should Be 6
	}
	It "sets replacement index/length for completion at the end of the input with parameter input" {
		$result = PoshTabExpansion2Wrapper "Get-ChI | Get-Co foo" 16
		$result.ReplacementIndex | Should Be 10
		$result.ReplacementLength | Should Be 6
	}
}

Describe "PoshHumpTabExpansion2 - parameter completion" {
	Mock GetParameters -ParameterFilter {$commandName -eq "Get-Foo1"} -MockWith { @("-TestOne", "-TestTwo", "-TestThree")}
	Mock GetParameters -ParameterFilter {$commandName -eq "Get-Help"} -MockWith { @("-Category", "-Component", "-Debug", "-Detailed", "-ErrorAction", "-ErrorVariable", "-Examples", "-Full", "-Functionality", "-InformationAction", "-InformationVariable", "-Name", "-Online", "-OutBuffer", "-OutVariable", "-Parameter", "-Path", "-PipelineVariable", "-Role", "-ShowWindow", "-Verbose", "-WarningAction", "-WarningVariable")}
	It "simple completion" {
		,(PoshTabExpansion2Wrapper "Get-Help -Fu").CompletionMatches | Should MatchArrayOrdered @("-Full", "-Functionality")
	}
	It "matches with hump completion on capitals"{
		,(PoshTabExpansion2Wrapper "Get-Foo1 -TT").CompletionMatches | Should MatchArrayOrdered @("-TestTwo", "-TestThree")
	}
	It "matches with hump completion on capitals and lowercase"{
		,(PoshTabExpansion2Wrapper "Get-Foo1 -TTw").CompletionMatches | Should MatchArrayOrdered @("-TestTwo")
	}
	It "matches in the middle of the command text" {
		$result = PoshTabExpansion2Wrapper "Get-Help -Fu -Bar" 12
		$result.ReplacementIndex | Should Be 9
		$result.ReplacementLength | Should Be 3
		,$result.CompletionMatches | Should MatchArrayOrdered @("-Full", "-Functionality")
	}
	It "matches with hump completion on capitals"{
		$result = PoshTabExpansion2Wrapper "Get-Foo1 -TT | Write-Host" 12
		$result.ReplacementIndex | Should Be 9
		$result.ReplacementLength | Should Be 3
		,$result.CompletionMatches | Should MatchArrayOrdered @("-TestTwo", "-TestThree")
	}

}


# TODO
#  * add tests for completion of variable names