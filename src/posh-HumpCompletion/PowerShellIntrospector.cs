using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;

namespace PoshHumpCompletion
{
    // TODO - this file has become a dumping ground - clean it up!
    public class PowerShellIntrospector
    {
        public virtual string[] GetCommandNames()
        {
            var scriptBlock = ScriptBlock.Create("Get-Command | Select-Object -ExpandProperty Name");
            var result = scriptBlock.Invoke();
            var commandNames = result.Select(o => (string)o.BaseObject).ToArray();
            return commandNames;
        }

        public virtual string[] GetParameterNames(string commandName)
        {
            var result = ScriptBlock.Create($"Get-Command {commandName} -ShowInfo").Invoke();
            if (result.Count ==0)
            {
                return Array.Empty<string>();
            }
            if (result[0].Properties["CommandType"].Value.ToString() == "Alias")
            {
                result = ScriptBlock.Create($"Get-Command {result[0].Properties["Definition"].Value.ToString()} -ShowInfo").Invoke();
            }
            if (result.Count == 0)
            {
                return Array.Empty<string>();
            }
            // TODO - look at whether we can determine the parameter set to be smarter about the parameters we complete
            var cmdletInfo = (CmdletInfo)result[0].BaseObject;
            return cmdletInfo.Parameters
                        .Select(p => "-" + p.Value.Name)
                        .OrderBy(x => x)
                        .Distinct()
                        .ToArray();
        }
        public virtual string[] GetVariableNames()
        {
            var result = ScriptBlock.Create($"Get-Variable").Invoke();
            return result.Select(o => ((PSVariable)o.BaseObject).Name).ToArray();
        }
    }
}
