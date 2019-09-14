
module roman_numerals;

import std.stdio;

// Returns an anoymous InputRange of strings on which we can iterate 
// to return the full string in Roman numerals.
// Doesn't use GC since Romans didn't have GC, back in the days.
// Solution is based off of user fsouza's, but using ranges and GC to make
// it more challenging for me.
pure auto convertNoGc(int n) @nogc
{
    struct NumData {
        int Number;
        string Letter;
    }
    struct RomanRange {
        immutable(NumData[13]) numerals = [ 
            {1000, "M"}, {900, "CM"}, {500, "D"}, {400, "CD"}, {100, "C"}, {90, "XC"}, 
            {50, "L"}, {40, "XL"}, {10, "X"}, {9, "IX"}, {5, "V"}, {4, "IV"}, {1, "I"} ];

        // State of this generator:
        int i = 0;        // Current place in the numerals array
        int number;       // Current number, starts with the given one and chopped off every time we advance in the array
        int repeat = 0;   // Number of times to repeat the current numeral, can be 0.

        // Utility function which advances in the array until we find the place to stop.
        // Chopping off the number is done in popFront().
        void advance() @nogc {
            // Advance in numerals until we get to one below our number
            while(i < numerals.length && this.number < numerals[i].Number)
                i += 1;
            // If we got to the end, don't go on
            if (i == numerals.length)
                return;
            // Calculate the number of times to repeat the current numeral
            // -1 because foreach calls first to front() so when we exit the ctor
            // or popFront() we are already in the first iteration of this numeral.
            repeat = (number / numerals[i].Number) - 1;
        }
        this(int number) @nogc { 
            this.number = number;
            // In the beginning we should already be on the first place in the array
            // since foreach will call front() . So we advance here in the ctor to be ready.
            advance();
        }
        string front() @nogc {
            return numerals[i].Letter;
        }
        bool empty() @nogc {
            return i >= numerals.length;
        }
        void popFront() @nogc {
            if (repeat > 0) {
                // If we should be repeating the current numeral, don't adavnce i or chop the number,
                // just count down, front() will return the same numeral.
                repeat -= 1;
            } else {
                // Chop the number
                number %= numerals[i].Number;
                advance();
            }
        }
    }
    return RomanRange(n);
}
string convert(int n)
{
    import std.array;
    import std.exception;
    enforce(n <= 3000, "The years 3001 or above are not achievable, even by Pax Romana");

    // Throw away the nice @nogc we worked so hard above by allocating and using join :-)
    // since the unit test requires a string and we have to allocate.
    return join(convertNoGc(n));
}


unittest
{

immutable int allTestsEnabled = 1;

// one_yields_I
{
	writefln("Conversion of 1: %s", convert(1));
	assert("I" == convert(1));
}
static if (allTestsEnabled)
{

// two_yields_II
{
	writefln("Conversion of 2: %s", convert(2));
	assert("II" == convert(2));
}

// three_yields_III
{
	writefln("Conversion of 3: %s", convert(3));
	assert("III" == convert(3));
}

// four_yields_IV
{
	writefln("Conversion of 4: %s", convert(4));
	assert("IV" == convert(4));
}

// five_yields_V
{
	writefln("Conversion of 5: %s", convert(5));
	assert("V" == convert(5));
}

// six_yields_VI
{
	writefln("Conversion of 6: %s", convert(6));
	assert("VI" == convert(6));
}

// nine_yields_IX
{
	writefln("Conversion of 9: %s", convert(9));
	assert("IX" == convert(9));
}

// twenty_seven_yields_XXVII
{
	writefln("Conversion of 27: %s", convert(27));
	assert("XXVII" == convert(27));
}

// forty_eight_yields_XLVIII
{
	writefln("Conversion of 48: %s", convert(48));
	assert("XLVIII" == convert(48));
}

// fifty_nine_yields_LIX
{
	writefln("Conversion of 59: %s", convert(59));
	assert("LIX" == convert(59));
}

// ninety_three_yields_XCIII
{
	writefln("Conversion of 93: %s", convert(93));
	assert("XCIII" == convert(93));
}

// one_hundred_forty_one_yields_CXLI
{
	writefln("Conversion of 141: %s", convert(141));
	assert("CXLI" == convert(141));
}

// one_hundred_sixty_three_yields_CLXIII
{
	writefln("Conversion of 163: %s", convert(163));
	assert("CLXIII" == convert(163));
}

// four_hundred_two_yields_CDII
{
	writefln("Conversion of 402: %s", convert(402));
	assert("CDII" == convert(402));
}

// five_hundred_seventy_five_yields_DLXXV
{
	writefln("Conversion of 575: %s", convert(575));
	assert("DLXXV" == convert(575));
}

// nine_hundred_eleven_yields_CMXI
{
	writefln("Conversion of 911: %s", convert(911));
	assert("CMXI" == convert(911));
}

// one_thousand_twenty_four_yields_MXXIV
{
	writefln("Conversion of 1024: %s", convert(1024));
	assert("MXXIV" == convert(1024));
}

// three_thousand_yields_MMM)
{
	writefln("Conversion of 3000: %s", convert(3000));
	assert("MMM" == convert(3000));
}

}

}
