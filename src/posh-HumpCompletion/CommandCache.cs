using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;

namespace PoshHumpCompletion
{
    public class CommandCache
    {
        public Dictionary<string, Dictionary<string, List<CommandSummary>>> CommandsByVerbAndHumpForm { get; private set; }

        private object _cacheLoadLock = new object(); // lock this when working with _cacheLoadWaitHandle
        private WaitHandle _cacheLoadWaitHandle = null;
        private readonly PowerShellIntrospector _introspector;

        public CommandCache(PowerShellIntrospector introspector)
        {
            _introspector = introspector;
        }

        public void LoadAsync()
        {
            try
            {
                Debug.WriteLine($"Entered {nameof(LoadAsync)}");
                if (CommandsByVerbAndHumpForm != null || _cacheLoadWaitHandle != null)
                {
                    return;
                }
                lock (_cacheLoadLock)
                {
                    if (CommandsByVerbAndHumpForm != null || _cacheLoadWaitHandle != null)
                    {
                        return;
                    }

                    var resetEvent = new ManualResetEvent(false);
                    _cacheLoadWaitHandle = resetEvent;

                    var runspace = RunspaceFactory.CreateRunspace();
                    runspace.Open();

                    // Set variable to prevent installation of the TabExpansion function in the created runspace
                    // Otherwise we end up recursively spinning up runspaces to load the commands!
                    runspace.SessionStateProxy.SetVariable("poshhumpSkipTabCompletionInstall", true);

                    var powershell = PowerShell.Create();
                    powershell.Runspace = runspace;
                    powershell.AddScript("Get-Command | Select-Object -ExpandProperty Name");
                    var output = new PSDataCollection<PSObject>();
                    Debug.WriteLine("Getting Commands...");

                    powershell.BeginInvoke(output, new PSInvocationSettings(), iar =>
                    {
                        try
                        {
                            output = powershell.EndInvoke(iar);
                            Debug.WriteLine("Creating command array");
                            var commandNames = output.Select(o => (string)o.BaseObject).ToArray();
                            Debug.WriteLine("Creating command lookup");
                            var lookup = GroupCommands(commandNames);
                            Debug.WriteLine("Locking on cache loader");
                            lock (_cacheLoadLock)
                            {
                                Debug.WriteLine("Setting cache");
                                CommandsByVerbAndHumpForm = lookup;
                                resetEvent.Set(); // trigger the event for anyone waiting
                                _cacheLoadWaitHandle = null; // clear out the reference to avoid other waiting
                            }
                        }
                        catch (Exception ex)
                        {
                            Debug.WriteLine(ex.ToString());
                        }
                    }, null);

                }

            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.ToString());
            }
        }
        public void EnsureLoaded()
        {
            var waitHandle = _cacheLoadWaitHandle;
            if (waitHandle != null)
            {
                Debug.WriteLine("Waiting on load...");
                waitHandle.WaitOne();
                Debug.WriteLine("Wait completed");
            }
            if (_cacheLoadWaitHandle == null && CommandsByVerbAndHumpForm == null)
            {
                lock (_cacheLoadLock)
                {
                    Debug.WriteLine("Loading command cache (sync)");
                    if (_cacheLoadWaitHandle == null && CommandsByVerbAndHumpForm == null)
                    {
                        string[] commandNames = _introspector.GetCommandNames();
                        var lookup = GroupCommands(commandNames);
                        CommandsByVerbAndHumpForm = lookup;
                    }
                }
            }
        }

        public void Clear()
        {
            var waitHandle = _cacheLoadWaitHandle;
            if (waitHandle != null)
            {
                waitHandle.WaitOne();
            }
            lock (_cacheLoadLock)
            {
                _cacheLoadWaitHandle = null;
                CommandsByVerbAndHumpForm = null;
            }
        }
        private static Dictionary<string, Dictionary<string, List<CommandSummary>>> GroupCommands(string[] commandNames)
        {
            // Create a nested dictionary structure
            // First level is keyed on verb
            // second level is keyed on the hump form of the suffix
            return commandNames
                .Where(n=>n.Contains('-')) // fails on summary creation otherwise
                .Select(n=>new CommandSummary(n))
                .GroupBy(c => new VerbSuffixHumpFormKey { Verb = c.Verb.ToLowerInvariant(), SuffixHumpForm = c.SuffixHumpForm })
                .GroupBy(c => c.Key.Verb)
                .ToDictionary(g => g.Key.ToLowerInvariant(), g => g.ToDictionary(g2 => g2.Key.SuffixHumpForm, g2 => g2.ToList()))
                ;
        }
    }
}
