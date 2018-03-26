namespace PoshHumpCompletion
{
    public class HumpCompletionResult
    {
        public int ReplacementIndex { get; set; }
        public int ReplacementLength { get; set; }
        public string[] CompletionMatches { get; set; }
    }
}