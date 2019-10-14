module luhn;

bool valid(string s) {
    import std.range;
    import std.algorithm;
    import std.ascii;
    import std.conv;

    // Filter out invalid characters
    if (!s.all!(c => c.isWhite || c.isDigit)) {
        return false;
    }
    // Filter out spaces, before checking the length.
    // A single digit with spaces is still invalid.
    s = s.filter!isDigit.to!string;
    if (s.length <= 1) {
        return false;
    }
    auto sum = s
        .retro // Reverse before counting backwards
        .map!"a - '0'"
        .enumerate
        .map!(t => (t.index % 2 == 1) ? 
              // modolu 9 won't work correctly on "9" itself, since we should return 9 instead of 0.
              (t.value == 9) ? 9 : (t.value * 2) % 9  
              : t.value)
        .sum;
    return sum % 10 == 0;
}

unittest
{
    immutable int allTestsEnabled = 1;

    // single digit strings can not be valid
    assert(!valid("1"));

    static if (allTestsEnabled)
    {
        // a single zero is invalid
        assert(!valid("0"));

        // a simple valid SIN that remains valid if reversed
        assert(valid("059"));

        // a simple valid SIN that becomes invalid if reversed
        assert(valid("59"));

        // a valid Canadian SIN
        assert(valid("055 444 285"));

        // invalid Canadian SIN
        assert(!valid("055 444 286"));

        // invalid credit card
        assert(!valid("8273 1232 7352 0569"));

        // valid number with an even number of digits
        assert(valid("095 245 88"));

        // valid number with an odd number of spaces
        assert(valid("234 567 891 234"));

        // valid strings with a non-digit added at the end become invalid
        assert(!valid("059a"));

        // valid strings with punctuation included become invalid
        assert(!valid("055-444-285"));

        // valid strings with symbols included become invalid
        assert(!valid("055# 444$ 285"));

        // single zero with space is invalid
        assert(!valid(" 0"));

        // more than a single zero is valid
        assert(valid("0000 0"));

        // input digit 9 is correctly converted to output digit 9
        assert(valid("091"));

        /*
        Convert non-digits to their ascii values and then offset them by 48 sometimes accidentally declare an invalid string to be valid. 
        This test is designed to avoid that solution.
        */

        // using ascii value for non-doubled non-digit isn't allowed
        assert(!valid("055b 444 285"));

        // using ascii value for doubled non-digit isn't allowed
        assert(!valid(":9"));
    }

}
