using System;
using System.Diagnostics;
using System.Linq;
using System.Management.Automation.Language;
using System.Text.RegularExpressions;

namespace PoshHumpCompletion
{
    public class HumpCompletion
    {
        private static readonly Lazy<HumpCompletion> _instanceInitializer = new Lazy<HumpCompletion>();
        public static HumpCompletion Instance => _instanceInitializer.Value;

        private readonly PowerShellIntrospector _introspector;

        public HumpCompletion()
            : this(new PowerShellIntrospector())
        {
        }
        public HumpCompletion(PowerShellIntrospector introspector)
        {
            _introspector = introspector;
            _commandCache = new CommandCache(introspector);
        }

        private readonly CommandCache _commandCache;
        public CommandCache CommandCache => _commandCache;

        public HumpCompletionResult Complete(ScriptBlockAst ast, int offset)
        {
            Debug.WriteLine($"***** In PoshHumpTabExpansion2 - offset {offset}");
            var statements = ast.EndBlock.Statements;
            var pipelineElements = ((PipelineAst)statements[0]).PipelineElements;
            var command = pipelineElements[pipelineElements.Count - 1];
            string commandName = null;
            if (command is CommandAst commandAst)
            {
                commandName = commandAst.GetCommandName();
            }
            Debug.WriteLine($"Command name: {commandName}");

            // We want to find any NamedAttributeArgumentAst objects where the Ast extent includes $offset
            Func<Ast, bool> predicate = astToTest => astToTest.Extent.StartOffset < offset
                                                        && astToTest.Extent.EndOffset >= offset;
            var asts = ast.FindAll(predicate, searchNestedScriptBlocks: true).ToArray();

            var astCount = asts.Length;

            //$msg = ($asts | ForEach-Object { $_.GetType().Name}) -join ", "
            //DebugMessage "AstsInExtent ($astCount): $msg"

            if (astCount > 2
                && asts[astCount - 2] is CommandAst
                && asts[astCount - 1] is StringConstantExpressionAst)
            {
                // AST chain ends with CommandAst, StringConstantExpressionAst
                Debug.WriteLine("Invoking command completion...");
                return CompleteCommand(ast, asts);
            }
            if (astCount > 2
                && asts[astCount - 2] is CommandAst
                && asts[astCount - 1] is CommandParameterAst)
            {
                Debug.WriteLine("Calling parameter completion");
                return CompleteParameter(ast, asts);
            }
            if (astCount > 1
                && asts[astCount - 1] is VariableExpressionAst)
            {
                Debug.WriteLine("Calling variable completion");
                return CompleteVariable(ast, asts);
            }
            return null;

            //$msg = ($result.CompletionMatches) -join ", "
            //DebugMessage "Returning: Count=$($result.CompletionMatches.Length), values=$msg"
        }

        public HumpCompletionResult CompleteCommand(Ast ast, Ast[] asts)
        {
            Debug.WriteLine("In command completion");
            try
            {
                var astCount = asts.Length;
                var commandAst = (CommandAst)asts[astCount - 2];
                var stringAst = asts[astCount - 1];
                var extentStart = stringAst.Extent.StartOffset;
                var extentEnd = stringAst.Extent.EndOffset;

                Debug.WriteLine($"CommandAst match: '{string.Join(",", commandAst.CommandElements)}' - {extentStart}:{extentEnd}");

                var commandName = ast.ToString().Substring(extentStart, extentEnd - extentStart);

                CommandCache.EnsureLoaded();
                var commandInfo = new CommandSummary(commandName);
                var verb = commandInfo.Verb;
                var suffix = commandInfo.Suffix;
                var suffixRegexForm = GetRegexForm(suffix);
                Debug.WriteLine($"Command Name: '{commandName}, suffixRegexForm: '{suffixRegexForm}'");

                var commands = CommandCache.CommandsByVerbAndHumpForm;
                var verbLower = verb.ToLowerInvariant();
                Debug.WriteLine($"Cache keys: {commands.Keys.Count}");
                if (commands.ContainsKey(verbLower))
                {
                    // TODO - revisit this LINQ chain!!
                    var matches = commands[verbLower]
                        .Where(dictionaryEntry => dictionaryEntry.Key.StartsWith(commandInfo.SuffixHumpForm))
                        .SelectMany(dictionaryEntry => dictionaryEntry.Value)
                        .Where(value => Regex.IsMatch(value.Suffix, suffixRegexForm))
                        .Select(value => value.Command)
                        .OrderBy(v => v)
                        .ToArray();

                    return new HumpCompletionResult // TODO - create type
                    {
                        ReplacementIndex = stringAst.Extent.StartOffset,
                        ReplacementLength = stringAst.Extent.EndOffset - stringAst.Extent.StartOffset,
                        CompletionMatches = matches
                    };
                }
                else
                {
                    Debug.WriteLine($"No matching verb {verbLower}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.ToString());
                return null;
            }
        }

        public HumpCompletionResult CompleteParameter(Ast ast, Ast[] asts)
        {
            Debug.WriteLine("In parameter completion");
            try
            {
                var astCount = asts.Length;
                var commandAst = (CommandAst)asts[astCount - 2];
                var parameterAst = (CommandParameterAst)asts[astCount - 1];
                var extentStart = parameterAst.Extent.StartOffset;
                var extentEnd = parameterAst.Extent.EndOffset;
                Debug.WriteLine($"ParameterAst match: '{string.Join(",", commandAst.CommandElements)}' - {extentStart}:{extentEnd}");

                var commandName = ((StringConstantExpressionAst)commandAst.CommandElements[0]).Value;
                var parameterName = ast.ToString().Substring(extentStart, extentEnd - extentStart);
                var regexForm = GetRegexForm(parameterName);
                Debug.WriteLine($"ParameterName: '{parameterName}', regexForm '{regexForm}'");

                var parameters = _introspector.GetParameterNames(commandName);
                var completionMatches = parameters
                    .Where(p => Regex.IsMatch(p, regexForm))
                    .ToArray();

                return new HumpCompletionResult
                {
                    ReplacementIndex = extentStart,
                    ReplacementLength = extentEnd - extentStart,
                    CompletionMatches = completionMatches
                };
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.ToString());
                return null;
            }
        }

        public HumpCompletionResult CompleteVariable(Ast ast, Ast[] asts) // TODO - review the parameters
        {
            Debug.WriteLine("In variable completion");
            try
            {
                // TODO - EnsureHumpCompletionCache
                var astCount = asts.Length;
                var variableAst = (VariableExpressionAst)asts[astCount - 1];
                var extentStart = variableAst.Extent.StartOffset;
                var extentEnd = variableAst.Extent.EndOffset;
                var variableName = ast.ToString().Substring(extentStart + 1, extentEnd - extentStart - 1); // +1 is to skip the '$'' prefix
                Debug.WriteLine($"VariableAst match: '{variableName} - {extentStart}:{extentEnd}");

                var regexForm = GetRegexForm(variableName);
                Debug.WriteLine($"VariableName: '{variableName}', regexForm '{regexForm}'");

                var completionMatches = _introspector.GetVariableNames()
                    .Where(p => Regex.IsMatch(p, regexForm))
                    .Select(s => "$" + s)
                    .ToArray();

                return new HumpCompletionResult
                {
                    ReplacementIndex = extentStart,
                    ReplacementLength = extentEnd - extentStart,
                    CompletionMatches = completionMatches
                };
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.ToString());
                return null;
            }
        }

        public static string GetRegexForm(string suffix)
        {
            // create a wildcard form of a suffix. E.g. for "AzRGr" return "Az.*R.*Gr.*"
            if (string.IsNullOrEmpty(suffix))
            {
                return ".*";
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
                    result += ".*";
                }
                result += suffix[i];
            }
            result += ".*";
            return result;
        }
    }
}
