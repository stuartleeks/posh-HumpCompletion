using System;
using System.Collections.Generic;
using System.Text;
using Xunit;

namespace PoshHumpCompletion.Tests
{
    public class GetRegexFormTests
    {

        [Fact]
        public void WithOnlyUpperCaseCharacters()
        {
            With("CI")
                .Expect("C.*I.*");
        }
        [Fact]
        public void WithLowerCaseCharacters()
        {
            With("ChI")
                .Expect("Ch.*I.*");
        }
        [Fact]
        public void LongerTest()
        {
            With("ARReGr")
                .Expect("A.*R.*Re.*Gr.*");
        }
        [Fact]
        public void Parameters()
        {
            With("-TT")
                .Expect("-T.*T.*");
        }

        private RegexTestHelper With(string input)
        {
            return new RegexTestHelper(input);
        }

        private class RegexTestHelper
        {
            private string _input;
            public RegexTestHelper(string input)
            {
                _input = input;

            }
            public void Expect(string expected)
            {
                var actual = HumpCompletion.GetRegexForm(_input);
                Assert.Equal(expected, actual);
            }
        }
    }
}
