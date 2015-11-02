$packageName = 'posh-HumpCompletion'
$sourcePath = Split-Path -Parent $MyInvocation.MyCommand.Definition

$targetPath = Join-Path ([System.Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Modules\posh-HumpCompletion"

if(Test-Path $targetPath){
    Remove-Item -Path $targetPath -Recurse -Force
}

# remove profile entry
$newprofile = Get-Content $PROFILE | ?{-not $_.Contains("posh-HumpCompletion") }
$newprofile | Set-Content $PROFILE