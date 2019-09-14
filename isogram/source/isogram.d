module isogram;

// This version is more concise but will take much longer
// It also allocates memory unnnecessarily due to the call to array() below,
// since group() and sort() don't work with a lazy collection.
bool isIsogramFunctional(string s) {
    import std.array: array;
    import std.ascii: isAlpha, toLower;
    import std.algorithm: sort, all, group, filter, map;

    return s.filter!isAlpha.map!toLower.array.sort.group.all!(t => t[1] == 1);
}

// This version is longer to write but takes less time since
// it returns a result as soon as we find it's not an isogram.
bool isIsogramIterative(string s) {
    import std.algorithm;
    import std.ascii;
    enum numLetters = ('z' - 'a') + 1;
    bool[numLetters] letterFlags = false;
    foreach(c; s) {
        if (!c.isAlpha)
            continue;
        const i = c.toLower - 'a';
        if (letterFlags[i])
            return false;
        letterFlags[i] = true;
    }
    return true;
}

bool isIsogram(string s) {
    return isIsogramFunctional(s);
}

unittest
{
    immutable int allTestsEnabled = 1;

    // empty string
    assert(isIsogram(""));

    static if (allTestsEnabled)
    {
        // isogram with only lower case characters
        assert(isIsogram("isogram"));

        // word with one duplicated character
        assert(!isIsogram("eleven"));

        // word with one duplicated character from the end of the alphabet
        assert(!isIsogram("zzyzx"));

        // longest reported english isogram
        assert(isIsogram("subdermatoglyphic"));

        // word with duplicated character in mixed case
        assert(!isIsogram("Alphabet"));

        // word with duplicated character in mixed case, lowercase first
        assert(!isIsogram("alphAbet"));

        // hypothetical isogrammic word with hyphen
        assert(isIsogram("thumbscrew-japingly"));

        // hypothetical word with duplicated character following hyphen
        assert(!isIsogram("thumbscrew-jappingly"));

        // isogram with duplicated hyphen
        assert(isIsogram("six-year-old"));

        // made-up name that is an isogram
        assert(isIsogram("Emily Jung Schwartzkopf"));

        // duplicated character in the middle
        assert(!isIsogram("accentor"));

        // same first and last characters
        assert(!isIsogram("angola"));
    }
}
