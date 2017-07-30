$Runspace = $null
$Powershell = $null
function local:EnsureHumpCompletionCommandCache() {
    if ($global:HumpCompletionCommandCache -eq $null) {
        if (($script:runspace -eq $null) -or ($poshhumpLoadCommandsSync) ) {
            DebugMessage -message "loading command cache"
            $global:HumpCompletionCommandCache = GetCommandsWithVerbAndHumpSuffix
            DebugMessage -message "loading command cache - load complete $($global:HumpCompletionCommandCache.Keys.Count)"
            return $true;
        }
        else {
            DebugMessage -message "loading command cache - wait on async load"
            if ($script:iar.IsCompleted) {
                $tempResult = $script:powershell.EndInvoke($script:iar)
                DebugMessage -message "loading command cache - got  tempResult.result.Keys.Count: $($tempResult.result.Keys.Count)"
                $global:HumpCompletionCommandCache = $tempResult.result
                $script:Powershell.Dispose()
                $script:Runspace.Close()
                $script:Runspace = $null            
                DebugMessage -message "loading command cache - async load complete $($global:HumpCompletionCommandCache.Keys.Count)"
                return $true;
            }
            else {
                return $false;
            }
        }
    } else {
        DebugMessage -message "got command cache"
        return $true
    }
}
function local:LoadHumpCompletionCommandCacheAsync(){
    DebugMessage -message "LoadHumpCompletionCommandCacheAsync"
    if ($script:Runspace -eq $null) {
        DebugMessage -message "LoadHumpCompletionCommandCacheAsync - starting..."
        $script:Runspace = [RunspaceFactory]::CreateRunspace()
        $script:Runspace.Open()
        $null = $script:Runspace.SessionStateProxy.Path.SetLocation($PSScriptRoot); ## set working dir for runspace

        # Set variable to prevent installation of the TabExpansion function in the created runspace
        # Otherwise we end up recursively spinning up runspaces to load the commands!
        $script:Runspace.SessionStateProxy.SetVariable('poshhumpSkipTabCompletionInstall', $true)

        $script:Powershell = [PowerShell]::Create()
        $script:Powershell.Runspace = $script:Runspace

        [void]$script:Powershell.AddScript( {
                try {
                    # working dir is set for the runspace
                    . "$pwd/common.ps1"
                    DebugMessage -message "AsyncLoad: Starting..."
                    $slCommands = GetCommandsWithVerbAndHumpSuffix
                    DebugMessage -message "AsyncLoad: Got $($slCommands.Keys.Count) Keys"
                    $wrappedResult = @{ "result" = $slCommands} # work around group enumeration as it loses the grouping!
                    return $wrappedResult
                }
                catch {
                    DebugMessage -message "!!!!exception in async load block"
                    return @{ "result" = "!!exception"}
                }
            })
        $script:iar = $script:PowerShell.BeginInvoke()
    }
}

function local:GetParameters($commandName) {
    $command = Get-Command  $commandName -ShowCommandInfo
    if ($command.CommandType -eq "Alias") {
        $command = Get-Command $command.Definition -ShowCommandInfo
    }
        
    # TODO - look at whether we can determine the parameter set to be smarter about the parameters we complete
    $command.ParameterSets `
        | Select-Object -ExpandProperty Parameters `
        | Select-Object -ExpandProperty Name -Unique `
        | ForEach-Object { "-$($_)" } `
        | Sort-Object
}

function local:PoshHumpTabExpansion2(
    [System.Management.Automation.Language.Ast]$ast, 
    [int]$offset) {
    
    $result = $null;
    DebugMessage "***** In PoshHumpTabExpansion2 - offset $offset"
    $statements = $ast.EndBlock.Statements
    $command = $statements.PipelineElements[$statements.PipelineElements.Count - 1]
    if ($command -is [System.Management.Automation.Language.CommandAst]) {
        $commandName = $command.GetCommandName()
    }
    else {
        $commandName = $null
    }
    DebugMessage "Command name: $commandName"


    # We want to find any NamedAttributeArgumentAst objects where the Ast extent includes $offset
    $offsetInExtentPredicate = {
        param($astToTest)
        return $offset -gt $astToTest.Extent.StartOffset -and 
        $offset -le $astToTest.Extent.EndOffset
    }
    $asts = $ast.FindAll($offsetInExtentPredicate, $true)
    $astCount = $asts.Count;
    
    $msg = ($asts | ForEach-Object { $_.GetType().Name}) -join ", "
    DebugMessage "AstsInExtent ($astCount): $msg"
    
    
    if ($astCount -gt 2 `
            -and $asts[$astCount - 2] -is [System.Management.Automation.Language.CommandAst] `
            -and $asts[$astCount - 1] -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
        # AST chain ends with CommandAst, StringConstantExpressionAst
        $result = PoshHumpTabExpansion2_Command $asts
    }
    elseif ($astCount -gt 2 `
            -and $asts[$astCount - 2] -is [System.Management.Automation.Language.CommandAst] `
            -and $asts[$astCount - 1] -is [System.Management.Automation.Language.CommandParameterAst]) {
        $result = PoshHumpTabExpansion2_Parameter $asts
    }
    elseif ($astCount -ge 1 `
            -and $asts[$astCount - 1] -is [System.Management.Automation.Language.VariableExpressionAst]) {
        $result = PoshHumpTabExpansion2_Variable $asts
    }
    
    
    $msg = ($result.CompletionMatches) -join ", "
    DebugMessage "Returning: Count=$($result.CompletionMatches.Length), values=$msg"
    return $result
}

function local:PoshHumpTabExpansion2_Command($asts) {
    $astCount = $asts.Count;
    $commandAst = $asts[$astCount - 2]
    $stringAst = $asts[$astCount - 1]
    $extentStart = $stringAst.Extent.StartOffset
    $extentEnd = $stringAst.Extent.EndOffset
    DebugMessage "CommandAst match: '$($commandAst.CommandElements.Value)' - $($extentStart):$($extentEnd)"
    $commandName = $ast.ToString().Substring($extentStart, $extentEnd - $extentStart)

    if (EnsureHumpCompletionCommandCache) {
        $commandInfo = GetCommandWithVerbAndHumpSuffix $commandName
        $verb = $commandInfo.Verb
        $suffix = $commandInfo.Suffix
        $suffixWildcardForm = GetWildcardForm $suffix 
        $wildcardForm = "$verb-$suffixWildcardForm"
        DebugMessage "CommandName: '$commandName', wildcardForm: '$wildcardForm'"
        $commands = $global:HumpCompletionCommandCache
        $verbLower = $verb.ToLowerInvariant()
        DebugMessage "Cache keys: $($commands.Keys.Count)"
        DebugMessage "Cache keys: $([string]::Join(',', $commands.Keys))"
        if ($commands[$verbLower] -ne $null) {
            $completionMatches = $commands[$verbLower].GetEnumerator() `
                | Where-Object { 
                # $_.Key is suffix hump form
                # Match on hump form of completion word
                $_.Key.StartsWith($commandInfo.SuffixHumpForm)
            } `
                | Select-Object -ExpandProperty Value `
                | Where-Object { $_.Suffix -clike $suffixWildcardForm } `
                | Select-Object -ExpandProperty Command `
                | Sort-Object
            
            $msg = $completionMatches -join ", "
            DebugMessage "cmd: Count=$($completionMatches.Length), values=$msg"

            $result = [PSCustomObject]@{
                ReplacementIndex  = $stringAst.Extent.StartOffset;
                ReplacementLength = $stringAst.Extent.EndOffset - $stringAst.Extent.StartOffset;
                CompletionMatches = $completionMatches
            };
            return $result
        }
        else{
            DebugMessage -message "No matching verb $verbLower"
        }
    }
    else {
        DebugMessage -message "No command cache"
    }
}
function local:PoshHumpTabExpansion2_Parameter($asts) {
    $commandAst = $asts[$astCount-2]
    $parameterAst = $asts[$astCount-1]
    $extentStart = $parameterAst.Extent.StartOffset
    $extentEnd = $parameterAst.Extent.EndOffset
    DebugMessage "ParameterAst match: '$($commandAst.CommandElements.Value)' - $($extentStart):$($extentEnd)"
    
    $commandName = $commandAst.CommandElements.Value
    $parameterName = $ast.ToString().Substring($extentStart, $extentEnd - $extentStart)
    $wildcardForm = GetWildcardForm $parameterName
    DebugMessage "ParameterName: '$parameterName', wildcardForm: '$wildcardForm'"

    $parameters = GetParameters -commandName $commandName

    $completionMatches = $parameters `
        | Where-Object { 
        # DebugMessage "Match test '$_', '$wildcardForm', match $($_ -clike $wildcardForm)"
        $_ -clike $wildcardForm 
    }
    
    $result = [PSCustomObject]@{
        ReplacementIndex  = $extentStart;
        ReplacementLength = $extentEnd - $extentStart;
        CompletionMatches = $completionMatches
    };
    return $result
}
function local:PoshHumpTabExpansion2_Variable($asts) {
    DebugMessage "************* variable completion *****************"
    $variableAst = $asts[$astCount - 1]
    $extentStart = $variableAst.Extent.StartOffset
    $extentEnd = $variableAst.Extent.EndOffset
    $variableNameWithPrefix = $ast.ToString().Substring($extentStart, $extentEnd - $extentStart)
    $variableName = $variableNameWithPrefix.TrimStart("`$")
    $wildcardForm = GetWildcardForm $variableName
    
    DebugMessage "VariableAst match: '$variableName' - $($extentStart):$($extentEnd)"

    $completionMatches = Get-Variable `
        | Select-Object -ExpandProperty Name `
        | Where-Object { 
        # DebugMessage "==== '$_' -clike '$wildcardForm' == $($_ -clike $wildcardForm)"
        $_ -clike $wildcardForm } `
        | Foreach-Object { "`$$_" }

    $result = [PSCustomObject]@{
        ReplacementIndex  = $extentStart;
        ReplacementLength = $extentEnd - $extentStart;
        CompletionMatches = $completionMatches
    };
    return $result
}

function Clear-HumpCompletionCommandCache() {
    [Cmdletbinding()]
    param()

    DebugMessage -message "PoshHumpTabExpansion:clearing command cache"
    $global:HumpCompletionCommandCache = $null
}
function Stop-HumpCompletion() {
    [Cmdletbinding()]
    param()

    $global:HumpCompletionEnabled = $false
}
function Start-HumpCompletion() {
    [Cmdletbinding()]
    param()
    
    $global:HumpCompletionEnabled = $true
}

# install the handler!
DebugMessage -message "Installing: Test PoshHumpTabExpansion2Backup function"
if ($poshhumpSkipTabCompletionInstall) {
    DebugMessage -message "Skipping tab expansion installation"
}
else {
    if (-not (Test-Path Function:\PoshHumpTabExpansion2Backup)) {

        if (Test-Path Function:\TabExpansion2) {
            DebugMessage -message "Installing: Backup TabExpansion2 function"
            Rename-Item Function:\TabExpansion2 PoshHumpTabExpansion2Backup
        }
        
        function global:TabExpansion2() {
            <# Options include:
                RelativeFilePaths - [bool]
                    Always resolve file paths using Resolve-Path -Relative.
                    The default is to use some heuristics to guess if relative or absolute is better.

            To customize your own custom options, pass a hashtable to CompleteInput, e.g.
                    return [System.Management.Automation.CommandCompletion]::CompleteInput($inputScript, $cursorColumn,
                        @{ RelativeFilePaths=$false } 
            #>

            [CmdletBinding(DefaultParameterSetName = 'ScriptInputSet')]
            Param(
                [Parameter(ParameterSetName = 'ScriptInputSet', Mandatory = $true, Position = 0)]
                [string] $inputScript,
                
                [Parameter(ParameterSetName = 'ScriptInputSet', Mandatory = $true, Position = 1)]
                [int] $cursorColumn,

                [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 0)]
                [System.Management.Automation.Language.Ast] $ast,

                [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 1)]
                [System.Management.Automation.Language.Token[]] $tokens,

                [Parameter(ParameterSetName = 'AstInputSet', Mandatory = $true, Position = 2)]
                [System.Management.Automation.Language.IScriptPosition] $positionOfCursor,
                
                [Parameter(ParameterSetName = 'ScriptInputSet', Position = 2)]
                [Parameter(ParameterSetName = 'AstInputSet', Position = 3)]
                [Hashtable] $options = $null
            )
            End {
                if ($psCmdlet.ParameterSetName -eq 'ScriptInputSet') {
                    $results = [System.Management.Automation.CommandCompletion]::CompleteInput(
                        <#inputScript#>  $inputScript,
                        <#cursorColumn#> $cursorColumn,
                        <#options#>      $options)
                }
                else {
                    $results = [System.Management.Automation.CommandCompletion]::CompleteInput(
                        <#ast#>              $ast,
                        <#tokens#>           $tokens,
                        <#positionOfCursor#> $positionOfCursor,
                        <#options#>          $options)
                }
                
                if ($psCmdlet.ParameterSetName -eq 'ScriptInputSet') {
                    $ast = [System.Management.Automation.Language.Parser]::ParseInput($inputScript, [ref]$tokens, [ref]$null)
                    # DebugMessage "Ast: $($ast.ToString())"
                }
                else {
                    $cursorColumn = $positionOfCursor.Offset
                }

                
                $poshHumpResult = PoshHumpTabExpansion2 $ast $cursorColumn
                if ($poshHumpResult -ne $null) {
                    $results.ReplacementIndex = $poshHumpResult.ReplacementIndex
                    $results.ReplacementLength = $poshHumpResult.ReplacementLength
                    
                    # From TabExpansionPlusPlus: Workaround where PowerShell returns a readonly collection that we need to add to.
                    if ($results.CompletionMatches.IsReadOnly) {
                        $collection = new-object System.Collections.ObjectModel.Collection[System.Management.Automation.CompletionResult]
                        $results.GetType().GetProperty('CompletionMatches').SetValue($results, $collection)
                    }
                    
                    # $results.CompletionMatches.Clear() # TODO - look at inserting at front instead of clearing as this removes standard completion! Augment vs override
                    $poshHumpResult.CompletionMatches | ForEach-Object { $results.CompletionMatches.Add($_)}
                }
                
                return $results 
            }
        }
        LoadHumpCompletionCommandCacheAsync
    }
}
$global:HumpCompletionEnabled = $true