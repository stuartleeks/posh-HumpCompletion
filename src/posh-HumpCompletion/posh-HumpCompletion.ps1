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
                
                $poshHumpResult = [PoshHumpCompletion.HumpCompletion]::Instance.Complete($ast,$cursorColumn)
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
        DebugMessage -message "Calling LoadHumpCompletionCommandCacheAsync..."        
        [PoshHumpCompletion.HumpCompletion]::Instance.CommandCache.LoadAsync()
    }
}
$global:HumpCompletionEnabled = $true