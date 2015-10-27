$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"


## Test Assertion functions takenb from: https://github.com/pester/Pester/blob/ebfb0997365fea29f25b2aa3065378a3765eff4c/Functions/Assertions/Test-Assertion.ps1
function Test-PositiveAssertion($result) {
    if (-not $result) {
        throw "Expecting expression to pass, but it failed"
    }
}

function Test-NegativeAssertion($result) {
    if ($result) {
        throw "Expecting expression to pass, but it failed"
    }
}

Describe "PesterMatchArray" {
    It "returns true for matching single item arrays" {
        Test-PositiveAssertion (PesterMatchArray @("a") @("a"))
    }
    It "returns true for matching single item and single item array" {
        Test-PositiveAssertion (PesterMatchArray "a" @("a"))
    }
    It "returns true for matching single item array and single item" {
        Test-PositiveAssertion (PesterMatchArray @("a") "a")
    }
    It "returns true for arrays with the same contents" {
        Test-PositiveAssertion (PesterMatchArray @("a", 1) @("a",1))
    }
    It "returns true for arrays with the same contents in different orders" {
        Test-PositiveAssertion (PesterMatchArray @("a", 1) @(1,"a"))
    }

    It "returns false if arrays differ in content" {
        Test-NegativeAssertion (PesterMatchArray @(1) @(2))
    }
    It "returns false if arrays differ in length" {
        Test-NegativeAssertion (PesterMatchArray @(1) @(1, 1))
    }
}
