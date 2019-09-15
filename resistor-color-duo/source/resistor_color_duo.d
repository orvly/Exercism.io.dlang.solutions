module resistor_color_duo;

struct ResistorColorDuo {
    import std.algorithm: fold, map;

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

    // NOTE: This can be marked nothrow for some reason, even if when given a wrong name it WILL throw.
    static uint value(string[] names) pure nothrow {
        return names.fold!( (number, currentName) => number * 10 + colorsDict[currentName] )(0);
    }
}
unittest
{
    const int allTestsEnabled = 1;

    // Brown and black
    assert(ResistorColorDuo.value(["brown", "black"]) == 10);

    static if (allTestsEnabled)
    {
        // Blue and grey
        assert(ResistorColorDuo.value(["blue", "grey"]) == 68);

        // Yellow and violet
        assert(ResistorColorDuo.value(["yellow", "violet"]) == 47);

        // Orange and orange
        assert(ResistorColorDuo.value(["orange", "orange"]) == 33);
    }

}
