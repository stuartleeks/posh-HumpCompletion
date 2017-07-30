$packageName = 'posh-HumpCompletion'
$sourcePath = Split-Path -Parent $MyInvocation.MyCommand.Definition

$targetPath = Join-Path ([System.Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Modules\posh-HumpCompletion"

if(Test-Path $targetPath){
    Write-Host "Remove previous module folder"
    Remove-Item -Path $targetPath -Recurse -Force | out-null
}
New-Item -ItemType Directory -Path $targetPath | out-null

Copy-Item "$sourcePath\*" $targetPath | out-null

# Adapted from http://www.west-wind.com/Weblog/posts/197245.aspx and discovered via posh-git
function Get-FileEncoding($Path) {
    $bytes = [byte[]](Get-Content $Path -Encoding byte -ReadCount 4 -TotalCount 4)

    if(!$bytes) { return 'utf8' }

    switch -regex ('{0:x2}{1:x2}{2:x2}{3:x2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3]) {
        '^efbbbf'   { return 'utf8' }
        '^2b2f76'   { return 'utf7' }
        '^fffe'     { return 'unicode' }
        '^feff'     { return 'bigendianunicode' }
        '^0000feff' { return 'utf32' }
        default     { return 'ascii' }
    }
}


if(-not (Test-Path $PROFILE))
{
    Write-Host "Creating profile: $PROFILE"
    New-Item $PROFILE -Type File -ErrorAction Stop -Force | out-null
}
Write-Host "Add posh-HumpCompletion to profile"
@"

# Load posh-HumpCompletion example profile
Import-Module posh-HumpCompletion

"@ | Out-File $PROFILE -Append -Encoding (Get-FileEncoding $PROFILE)

Write-Host "You will need to restart your PowerShell session (or reload your profile using "". `    $PROFILE"")"
