namespace PoshHumpCompletion
{
    class VerbSuffixHumpFormKey
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
            VerbSuffixHumpFormKey key = o as VerbSuffixHumpFormKey;
            if (key == null)
            {
                return false;
            }
            return key.Verb == Verb && key.SuffixHumpForm == SuffixHumpForm;
        }
    }
}
