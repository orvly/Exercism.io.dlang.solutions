module resistor_color;

struct ResistorColor {
private:
    static immutable uint[string] colorsDict;

    // A static immutable dictionary has to be initialized in a shared static constructor.
    shared static this() {
        colorsDict = [
            "black"   : 0,
            "brown"   : 1,
            "red"     : 2,
            "orange"  : 3,
            "yellow"  : 4,
            "green"   : 5,
            "blue"    : 6,
            "violet"  : 7,
            "grey"    : 8,
            "white"   : 9,
        ];
    }
public:
    static uint colorCode(string colorName) pure {
        return colorsDict[colorName];
    }

    static string[] colors() pure {
        import std.array: array;
        import std.algorithm: sort, map, minElement, find, maxElement;
        import std.range: iota;
        // Since the dictionary isn't searchable by its values, we have to do something :

        // 1) Sort the key-value pairs by the values, and return the values
        //    The following one liner does it:  it allocates an array, sorts it, takes the keys and copies
        //    them to another new array.
        //    The first array allocation is necessary since sort() works in place and requires a random access 
        //    container, while byKeyValue returns a range.
        //return colorsDict.byKeyValue.array.sort!((x,y) => x.value < y.value).map!(e => e.key).array;

        // OR
        // 2) Generate a sequence of the keys by iterating over the integer values in order.
        //    This is slightly more memory efficient, but possibly slower since we have to search
        //    every value.
        const values = colorsDict.values;
        auto keyValues = colorsDict.byKeyValue;
        return iota(values.minElement, values.maxElement + 1)
            .map!(n => keyValues.find!( (a, b) => a.value == b)(n).front.key) // Remember that .front returns the first item in a range, rather than [0]
            .array;
    }
}

unittest
{
    immutable int allTestsEnabled = 1;

    // Black
    assert(ResistorColor.colorCode("black") == 0);

    static if (allTestsEnabled)
    {
        // White
        assert(ResistorColor.colorCode("white") == 9);

        // Orange
        assert(ResistorColor.colorCode("orange") == 3);
        
        // Colors
        assert(ResistorColor.colors == [
                "black", "brown", "red", "orange", "yellow", "green", "blue",
                "violet", "grey", "white"
                ]);
    }

}
