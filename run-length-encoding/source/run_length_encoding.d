module run_length_encoding;

debug(2) import std.stdio;
import std.algorithm.iteration: group, map;
import std.algorithm: copy;
import std.array: appender, replicate;
import std.conv: to;

string encode(string s) {

    auto result = appender!string;
    result.reserve(s.length); // We need at most s.length, the actual encoded string might be shorter

    s.group // Group letters together
     .map!(nextTuple => (nextTuple[1] == 1) ? 
           // If a single letter, save just it
            nextTuple[0].to!string : 
           // If multiple letters, transform their number to mutable string append the letter, and 
           // get an immutable string
           (nextTuple[1].to!(dchar[]) ~ nextTuple[0]).to!string)
     .copy(result); // Append all sub-strings into the big result length
    return result.data; // appender.data returns the actual string
}

string decode(string s) {
    import std.regex: ctRegex, matchAll;
    import std.typecons: tuple;

    auto result = appender!string;
    result.reserve(s.length); // Preallocate, we need at least as much characters as in the original string
    // ?: - don't capture the whole sub expression
    // \d* - capture zero or more numbers
    // [a-zA-Z ] - capture a single letter
    auto ctr = ctRegex!(r"(?:(\d*)([a-zA-Z ]))");
    auto matches = matchAll(s, ctr); // Get all sub-sequences
    debug(2) writeln(matches.map!(m => m.map!(mm => mm)));
    // Each sub-sequence has 3 parts: the whole sub-capture (m[0]), the first sub-capture:
    // m[1] which corresponds to digits \d*, and the second one m[2] which corresponds to the 
    // single letter. No digit (empty string) means the letter is repeated a single time.
    matches.map!(m => tuple!("num", "letter")(m[1] == "" ? 1 : to!uint(m[1]), m[2]))
           // These 2 "map"s aren't really necessary, couldv'e been done in a single one,
           // without using the tuple. I did this just in order to play around with named tuples,
           // also, this makes the second map call below much more readable.
           .map!(t => t.letter.replicate(t.num))
           .copy(result); // Append all sub-strings into the big result length
    debug(2) writeln("*", result.data.to!string);
    return result.data; // appender.data returns the actual string
}

unittest
{
    immutable int allTestsEnabled = 1;

    // run-length encode a string

    // empty string
    assert(encode("") == "");

    static if (allTestsEnabled)
    {
        // single characters only are encoded without count
        assert(encode("XYZ") == "XYZ");

        // string with no single characters
        assert(encode("AABBBCCCC") == "2A3B4C");

        // single characters mixed with repeated characters
        assert(encode("WWWWWWWWWWWWBWWWWWWWWWWWWBBBWWWWWWWWWWWWWWWWWWWWWWWWB") == "12WB12W3B24WB");

        // multiple whitespace mixed in string
        assert(encode("  hsqq qww  ") == "2 hs2q q2w2 ");

        // lowercase characters
        assert(encode("aabbbcccc") == "2a3b4c");

        // run-length decode a string

        // empty string
        assert(decode("") == "");

        // string with no single characters
        assert(decode("XYZ") == "XYZ");

        // single characters with repeated characters
        assert(decode("2A3B4C") == "AABBBCCCC");

        // multiple whitespace mixed in string
        assert(decode("12WB12W3B24WB") == "WWWWWWWWWWWWBWWWWWWWWWWWWBBBWWWWWWWWWWWWWWWWWWWWWWWWB");

        // multiple whitespace mixed in string
        assert(decode("2 hs2q q2w2 ") == "  hsqq qww  ");

        // lower case string
        assert(decode("2a3b4c") == "aabbbcccc");

        // encode and then decode

        // encode followed by decode gives original string
        assert("zzz ZZ  zZ".encode.decode == "zzz ZZ  zZ");
    }
}
