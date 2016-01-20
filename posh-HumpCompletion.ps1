function DebugMessage($message) {
    $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    $appDomainId = [AppDomain]::CurrentDomain.Id
    [System.Diagnostics.Debug]::WriteLine("PoshHump: $threadId : $appDomainId :$message")

    [System.Diagnostics.Debug]::WriteLine("PoshHump: $message")
}

function GetCommandWithVerbAndHumpSuffix($commandName) {
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
function GetCommandsWithVerbAndHumpSuffix() {
    # TODO - add caching
    $commandsGroupedByVerb = Get-Command `
        | ForEach-Object { GetCommandWithVerbAndHumpSuffix $_.Name} `
        | Group-Object Verb
    $commands = @{}
    $commandsGroupedByVerb | ForEach-Object { $commands[$_.Name] = $_.Group | group-object SuffixHumpForm }
    return $commands
}
function GetWildcardSuffixForm($suffix){
    # create a wildcard form of a suffix. E.g. for "AzRGr" return "Az*R*Gr*"
    if ($suffix -eq $null -or $suffix.Length -eq 0){
        return "*"
    }
    $result = $suffix[0]
    for($i=1 ; $i -lt $suffix.Length ; $i++){
        if ([char]::IsUpper($suffix[$i])) {
            $result += "*"
        }
        $result += $suffix[$i]
    }
    $result += "*"
    return $result
}
$Powershell = $null
$Runspace = $null
function EnsureHumpCompletionCommandCache(){
    if ($global:HumpCompletionCommandCache -eq $null) {
        if ($script:runspace -eq $null) {
            DebugMessage -message "loading command cache"
            $global:HumpCompletionCommandCache = GetCommandsWithVerbAndHumpSuffix
        } else {
            DebugMessage -message "loading command cache - wait on async load"
            $foo = $script:Runspace.AsyncWaitHandle.WaitOne()
            $global:HumpCompletionCommandCache = $script:powershell.EndInvoke($script:iar).result
            $script:Powershell.Dispose()
            $script:Runspace.Close()
            $script:Runspace = $null            
            DebugMessage -message "loading command cache - async load commplete $($global:HumpCompletionCommandCache.Count)"
        }
    }
}
function LoadHumpCompletionCommandCacheAsync(){
    DebugMessage -message "LoadHumpCompletionCommandCacheAsync"
    if ($script:Runspace -eq $null) {
        DebugMessage -message "LoadHumpCompletionCommandCacheAsync - starting..."
        $script:Runspace = [RunspaceFactory]::CreateRunspace()
        $script:Runspace.Open()
        # Set variable to prevent installation of the TabExpansion function in the created runspace
        # Otherwise we end up recursively spinning up runspaces to load the commands!
        $script:Runspace.SessionStateProxy.SetVariable('poshhumpSkipTabCompletionInstall',$true)

        $script:Powershell = [PowerShell]::Create()
        $script:Powershell.Runspace = $script:Runspace

        $scriptBlock = {
            $result = GetCommandsWithVerbAndHumpSuffix
            @{ "result" = $result} # work around group enumeration as it loses the grouping!
        }
        $script:Powershell.AddScript($scriptBlock) | out-null
        
        $script:iar = $script:PowerShell.BeginInvoke()
    }
}
function PoshHumpTabExpansion($line) {

    if($line -match "^(?<verb>\S+)-(?<suffix>[A-Z]*)$") {
        EnsureHumpCompletionCommandCache
        
        $command = $matches[0]
        $commandInfo = GetCommandWithVerbAndHumpSuffix $command
        $verb = $matches['verb']
        $suffix= $matches['suffix']
        $suffixWildcardForm = GetWildcardSuffixForm $suffix 
        $wildcardForm = "$verb-$suffixWildcardForm"
        $commands = $global:HumpCompletionCommandCache
        if ($commands[$verb] -ne $null) {
            return $commands[$verb] `
                | Where-Object { 
                    # $_.Name is suffix hump form
                    # Match on hump form of completion word
                    $_.Name.StartsWith($commandInfo.SuffixHumpForm)
                } `
                | Select-Object -ExpandProperty Group `
                | Select-Object -ExpandProperty Command `
                | Where-Object { $_ -like $wildcardForm } `
                | Sort-Object
        }
    }
}

function Clear-HumpCompletionCommandCache() {
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
if ($poshhumpSkipTabCompletionInstall){
    DebugMessage -message "Skipping tab expansion installation"
} else {
    if (-not (Test-Path Function:\PoshHumpTabExpansionBackup)) {

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

            if ($result -ne $null) {
                $result
            } else {
                # Fall back on existing tab expansion
                if (Test-Path Function:\PoshHumpTabExpansionBackup) { 
                    PoshHumpTabExpansionBackup $line $lastWord 
                }
            }
        }
        LoadHumpCompletionCommandCacheAsync
    }
}
$global:HumpCompletionEnabled = $true