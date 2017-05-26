function DebugMessage($message) {
    # $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    # $appDomainId = [AppDomain]::CurrentDomain.Id
    # [System.Diagnostics.Debug]::WriteLine("PoshHump: $threadId : $appDomainId :$message")
    [System.Diagnostics.Debug]::WriteLine("PoshHump: $message")

    # Add-Content -Path "C:\temp\__test.txt" -Value $message
}

function GetCommandWithVerbAndHumpSuffix($commandName) {
    $separatorIndex = $commandName.IndexOf('-')
    if ($separatorIndex -ge 0) {
        $verb = $commandName.SubString(0, $separatorIndex)
        $suffix = $commandName.SubString($separatorIndex + 1)
        return [PSCustomObject] @{
            "Verb"           = $verb
            "Suffix"         = $suffix
            "SuffixHumpForm" = $suffix -creplace "[a-z]", "" # case sensitive replace
            "Command"        = $commandName 
        }   
    }    
}
function GetCommandsWithVerbAndHumpSuffix() {
    $rawCommands = Get-Command
    DebugMessage -message "!!!!RawCommands count $($rawCommands.Length)"
    $commandsGroupedByVerb = Get-Command `
        | ForEach-Object { GetCommandWithVerbAndHumpSuffix $_.Name} `
        | Group-Object Verb
    $commands = @{}
    $commandsGroupedByVerb | ForEach-Object { $commands[$_.Name] = $_.Group | group-object SuffixHumpForm }
    DebugMessage -message "!!!!Commands: $($commands.Length). KeyCount: $($commands.Keys.Count)"
    # return @(1,2,3)
    return $commands
}
function GetWildcardForm($suffix) {
    # create a wildcard form of a suffix. E.g. for "AzRGr" return "Az*R*Gr*"
    if ($suffix -eq $null -or $suffix.Length -eq 0) {
        return "*"
    }
    $startIndex = 1;
    $result = $suffix[0]
    if ($suffix[0] -eq '-') {
        $result += $suffix[1]
        $startIndex = 2
    }
    for ($i = $startIndex ; $i -lt $suffix.Length ; $i++) {
        if ([char]::IsUpper($suffix[$i])) {
            $result += "*"
        }
        $result += $suffix[$i]
    }
    $result += "*"
    return $result
}