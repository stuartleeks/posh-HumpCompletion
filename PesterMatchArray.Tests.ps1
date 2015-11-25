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

Describe "PesterMatchArrayUnordered" {
    It "returns true for matching single item arrays" {
        Test-PositiveAssertion (PesterMatchArrayUnordered @("a") @("a"))
    }
    It "returns true for matching single item and single item array" {
        Test-PositiveAssertion (PesterMatchArrayUnordered "a" @("a"))
    }
    It "returns true for matching single item array and single item" {
        Test-PositiveAssertion (PesterMatchArrayUnordered @("a") "a")
    }
    It "returns true for arrays with the same contents" {
        Test-PositiveAssertion (PesterMatchArrayUnordered @("a", 1) @("a",1))
    }
    It "returns true for arrays with the same contents in different orders" {
        Test-PositiveAssertion (PesterMatchArrayUnordered @("a", 1) @(1,"a"))
    }

    It "returns false if arrays differ in content" {
        Test-NegativeAssertion (PesterMatchArrayUnordered @(1) @(2))
    }
    It "returns false if arrays differ in length" {
        Test-NegativeAssertion (PesterMatchArrayUnordered @(1) @(1, 1))
    }
}

Describe "PesterMatchArrayOrdered" {
    It "returns true for matching single item arrays" {
        Test-PositiveAssertion (PesterMatchArrayOrdered @("a") @("a"))
    }
    It "returns true for matching single item and single item array" {
        Test-PositiveAssertion (PesterMatchArrayOrdered "a" @("a"))
    }
    It "returns true for matching single item array and single item" {
        Test-PositiveAssertion (PesterMatchArrayOrdered @("a") "a")
    }
    It "returns true for arrays with the same contents in the same order" {
        Test-PositiveAssertion (PesterMatchArrayOrdered @("a", 1) @("a",1))
    }
    It "returns false for arrays with the same contents in different orders" {
        Test-NegativeAssertion (PesterMatchArrayOrdered @("a", 1) @(1,"a"))
    }

    It "returns false if arrays differ in content" {
        Test-NegativeAssertion (PesterMatchArrayOrdered @(1) @(2))
    }
    It "returns false if arrays differ in length" {
        Test-NegativeAssertion (PesterMatchArrayOrdered @(1) @(1, 1))
    }
}
