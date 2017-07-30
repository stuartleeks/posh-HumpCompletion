Push-Location $PSScriptRoot
    [System.Diagnostics.Debug]::WriteLine("PoshHump:in psm1")
. .\common.ps1
. .\posh-HumpCompletion.ps1
Pop-Location