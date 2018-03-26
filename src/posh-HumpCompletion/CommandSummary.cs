using System;
using System.Text.RegularExpressions;

namespace PoshHumpCompletion
{
    public class CommandSummary
    {
        public CommandSummary()
        {
        }
        public CommandSummary(string commandName)
        {
            int separatorIndex = commandName.IndexOf('-');
            if (separatorIndex <= 0)
            {
                throw new ArgumentException("No '-' to separate Verb-Noun in commandName");
            }
            string verb = commandName.Substring(0, separatorIndex);
            string suffix = commandName.Substring(separatorIndex + 1);
            Command = commandName;
            Verb = verb;
            Suffix = suffix;
            SuffixHumpForm = Regex.Replace(suffix, "[a-z]", "");
        }
        public string Verb { get; set; }
        public string Suffix { get; set; }
        public string SuffixHumpForm { get; set; }
        public string Command { get; set; }
    }
}
