function GetLineNumber($stackTrace){
	if($stackTrace -match "at line: (\d*)"){
		$matches[1];
	} else {
		$null
	}
}
function GetFileName($stackTrace){
	if($stackTrace -match "at line: (?:\d*) in (.*)\n"){
		$matches[1];
	} else {
		$null
	}	
}
function FormatResult ($result){
	process {
		$lineNumber = GetLineNumber $_.StackTrace
		$file = GetFileName $_.StackTrace | Resolve-Path -Relative
		$collapsedMessage = $_.FailureMessage -replace "`n"," "
		$testDescription = "$($_.Describe):$($_.Name)"
		"$file;$lineNumber;${testDescription}:$collapsedMessage"
	}
}
Write-Host "Running tests..."
$results = Invoke-Pester -PassThru # can use -Quiet to suppress the default Pester output
$results.TestResult | ?{ -not $_.Passed} | FormatResult
Write-Host "Done"