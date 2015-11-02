# clean choco cache
dir $env:ProgramData\chocolatey\lib\posh-HumpCompletion* | Remove-Item -Recurse -Force
# install choco package from local dir
choco install posh-HumpCompletion -source "$pwd" -pre -force -y