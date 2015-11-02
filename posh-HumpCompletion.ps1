function DebugMessage($message){
    [System.Diagnostics.Debug]::WriteLine("PoshHump:$message")
}

function GetCommandWithVerbAndHumpSuffix($commandName){
    $separatorIndex = $commandName.IndexOf('-')
    if ($separatorIndex -ge 0){
        $verb = $commandName.SubString(0, $separatorIndex)
        $suffix = $commandName.SubString($separatorIndex+1)
        return [PSCustomObject] @{
            "Verb" = $verb
            "SuffixHumpForm" = $suffix -creplace "[a-z]","" # case sensitive replace
            "Command" = $commandName 
        }
    }    
}
function GetCommandsWithVerbAndHumpSuffix(){
    # TODO - add caching
    $commandsGroupedByVerb = Get-Command `
        | %{ GetCommandWithVerbAndHumpSuffix $_.Name} `
        | Group-Object Verb
    $commands = @{}
    $commandsGroupedByVerb | %{ $commands[$_.Name] = $_.Group | group-object SuffixHumpForm }
    return $commands
}
function PoshHumpTabExpansion($line){
    if ($global:HumpCompletionCommandCache -eq $null){
        DebugMessage -message "PoshHumpTabExpansion:loading command cache"
        $global:HumpCompletionCommandCache = GetCommandsWithVerbAndHumpSuffix
    }
    if($line -match "^(?<verb>\S+)-(?<suffix>[A-Z]*)"){
        $verb = $matches['verb']
        $suffix= $matches['suffix']
        $commands = $global:HumpCompletionCommandCache
        if ($commands[$verb] -ne $null){
            return $commands[$verb] | ?{ $_.Name.StartsWith($suffix)} | select -ExpandProperty Group | select -ExpandProperty Command | sort
        }
    }
}

function Clear-HumpCompletionCommandCache(){
    [Cmdletbinding()]
    param()

    DebugMessage -message "PoshHumpTabExpansion:clearing command cache"
    $global:HumpCompletionCommandCache = $null
}
function Stop-HumpCompletion(){
    [Cmdletbinding()]
    param()

    $global:HumpCompletionEnabled = $false
}
function Start-HumpCompletion(){
    [Cmdletbinding()]
    param()
    
    $global:HumpCompletionEnabled = $true
}

# install the handler!
DebugMessage -message "Installing: Test PoshHumpTabExpansionBackup function"
if(-not (Test-Path Function:\PoshHumpTabExpansionBackup)){

    if (Test-Path Function:\TabExpansion) {
        DebugMessage -message "Installing: Backup TabExpansion function"
        Rename-Item Function:\TabExpansion PoshHumpTabExpansionBackup
    }

    function TabExpansion($line="", $lastWord="") {
        $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

        if ($global:HumpCompletionEnabled) {
            DebugMessage -message "PoshHump:input: $lastBlock"
            $result = PoshHumpTabExpansion $lastBlock
        }

        if ($result -ne $null){
            $result
        } else {
            # Fall back on existing tab expansion
            if (Test-Path Function:\PoshHumpTabExpansionBackup) { 
                PoshHumpTabExpansionBackup $line $lastWord 
            }
        }
    }
}
$global:HumpCompletionEnabled = $true
