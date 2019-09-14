module reverse_string;

string reverseString(string s) {
    import std.array: array;
    import std.algorithm.mutation: reverse;
    import std.conv: to;

    return s
        .array       // Copy to a new mutable array
        .reverse     // Reverse the array
        .to!string;  // Convert back to a immutable string
}

unittest
{
    const int allTestsEnabled = 1;

    // an empty string
    assert(reverseString("") == "");

    static if (allTestsEnabled)
    {
        // a word
        assert(reverseString("robot") == "tobor");

        // a capitalized word
        assert(reverseString("Ramen") == "nemaR");

        // a sentence with punctuation
        assert(reverseString("I'm hungry!") == "!yrgnuh m'I");

        // a palindrome
        assert(reverseString("racecar") == "racecar");

        // an even-sized word
        assert(reverseString("drawer") == "reward");
    }
}
