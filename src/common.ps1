function DebugMessage($message) {
    # $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    # $appDomainId = [AppDomain]::CurrentDomain.Id
    # [System.Diagnostics.Debug]::WriteLine("PoshHump: $threadId : $appDomainId :$message")
    [System.Diagnostics.Debug]::WriteLine("PoshHump: $message")

    # Add-Content -Path "C:\temp\__test.txt" -Value $message
}

$source = @"
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
public class CommandSummary
{
	public string Verb { get; set; }
	public string Suffix { get; set; }
	public string SuffixHumpForm { get; set; }
	public string Command { get; set; }
}
public class Utils
{
	public static CommandSummary ConvertToSummary(string commandName)
	{
		int separatorIndex = commandName.IndexOf('-');
		if (separatorIndex >= 0)
		{
			string verb = commandName.Substring(0, separatorIndex);
			string suffix = commandName.Substring(separatorIndex + 1);
			return new CommandSummary
			{
				Command = commandName,
				Verb = verb,
				Suffix = suffix,
				SuffixHumpForm = Regex.Replace(suffix, "[a-z]", "")
			};
		}
		return null;
	}
	private class TempKey
	{
		public string Verb { get; set; }
		public string SuffixHumpForm { get; set; }
		
		public override int GetHashCode()
		{
			unchecked // Overflow is fine, just wrap
			{
				int hash = 17;
				hash = hash * 23 + Verb.GetHashCode();
				hash = hash * 23 + SuffixHumpForm.GetHashCode();
				return hash;
			}
		}
		public override bool Equals(object o)
		{
			TempKey key = o as TempKey;
			if (key == null)
			{
				return false;
			}
		 	return key.Verb == Verb && key.SuffixHumpForm == SuffixHumpForm;
		}
	}
	public static Dictionary<string, Dictionary<string, List<CommandSummary>>> GroupCommands(string[] commandNames)
	{
		return commandNames.Select(c => Utils.ConvertToSummary(c))
			.Where(o=>o!=null)
			.GroupBy(c => new TempKey { Verb = c.Verb.ToLowerInvariant(), SuffixHumpForm =  c.SuffixHumpForm })
			.GroupBy(c => c.Key.Verb)
			.ToDictionary(g => g.Key.ToLowerInvariant(), g => g.ToDictionary(g2 => g2.Key.SuffixHumpForm, g2 => g2.ToList()))
			;
	}
	public static string GetWildCardForm(string suffix)
	{
		// create a wildcard form of a suffix. E.g. for "AzRGr" return "Az*R*Gr*"
		if (string.IsNullOrEmpty(suffix))
		{
			return "*";
		}

		int startIndex = 1;
		string result = suffix[0].ToString();
		if (result == "-")
		{
			result += suffix[1];
			startIndex++;
		}
		for (int i = startIndex; i < suffix.Length; i++)
		{
			if (char.IsUpper(suffix[i]))
			{
				result += "*";
			}
			result += suffix[i];
		}
		result += "*";
		return result;
	}
}
"@

Add-Type -TypeDefinition $source -Language CSharp

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
    $commandNames = [string[]]($rawCommands | Select-Object -ExpandProperty Name)
    return [Utils]::GroupCommands($commandNames)
}
function GetWildcardForm($suffix) {
    return [Utils]::GetWildCardForm($suffix)
}