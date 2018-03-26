using PoshHumpCompletion;
using System.Collections.Generic;

namespace PoshHumpCompletion.TestHelpers
{
    public class MockPowerShellIntrospector : PowerShellIntrospector
    {
        public MockPowerShellIntrospector()
        {
        }
        public string[] CommandNames { get; set; }
        public override string[] GetCommandNames() {return CommandNames; }

        public Dictionary<string, string[]> ParameterNames { get; set; }
        public override string[] GetParameterNames(string command) { return ParameterNames[command]; }


        public string[] VariableNames { get; set; }
        public override string[] GetVariableNames() { return VariableNames; }

    }
}
