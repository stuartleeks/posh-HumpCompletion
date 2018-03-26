using System.Management.Automation;

namespace PoshHumpCompletion
{
    [Cmdlet("Clear", "HumpCompletionCacheCommand")]
    public class ClearHumpCompletionCacheCommand : PSCmdlet
    {
        protected override void EndProcessing()
        {
            HumpCompletion.Instance.CommandCache.Clear();
        }
    }
}
