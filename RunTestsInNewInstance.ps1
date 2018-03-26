param(
    # Use PowerShell Core (pwsh)?
    [Parameter()]
    [switch]
    $UsePwsh
)
if ($UsePwsh) {
    $powershell = "pwsh"
}
else {
    $powershell = "powershell"
} 
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Add-Type -Path "$here\src\posh-HumpCompletion\bin\Debug\netstandard2.0\posh-HumpCompletion.dll"

&$powershell -NoProfile -Command "`$PSVersionTable;Import-Module '$here\src\posh-HumpCompletion\bin\Debug\netstandard2.0\posh-HumpCompletion.psd1'; Invoke-Pester -Script '$here\src\posh-HumpCompletion\'" 