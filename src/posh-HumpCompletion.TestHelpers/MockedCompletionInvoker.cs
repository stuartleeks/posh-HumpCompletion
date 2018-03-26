using PoshHumpCompletion;
using System.Collections.Generic;
using System.Management.Automation.Language;

namespace PoshHumpCompletion.TestHelpers
{
    public class MockedCompletionInvoker
    {
        private string[] _commands;
        private Dictionary<string, string[]> _parametersByCommand = new Dictionary<string, string[]>();
        private string[] _variables;

        public MockedCompletionInvoker WithCommands(params string[] commands)
        {
            _commands = commands;
            return this;
        }
        public MockedCompletionInvoker WithParameters(string commandName, params string[]parameters)
        {
            _parametersByCommand.Add(commandName, parameters);
            return this;
        }
        public MockedCompletionInvoker WithVariables(params string[] variables)
        {
            _variables = variables;
            return this;
        }
        public HumpCompletionResult Complete(string input)
        {
            return Complete(input, input.Length);
        }
        public HumpCompletionResult Complete(string input, int offset)
        {
            Token[] tokens;
            ParseError[] parseError;
            var ast = Parser.ParseInput(input, out tokens, out parseError);

            var mockIntrospector = new MockPowerShellIntrospector
            {
                CommandNames = _commands,
                ParameterNames = _parametersByCommand,
                VariableNames = _variables
            };
            var completion = new HumpCompletion(mockIntrospector);
            return completion.Complete(ast, offset);
        }
    }
}
