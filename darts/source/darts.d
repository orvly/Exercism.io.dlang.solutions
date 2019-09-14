module darts;

uint score(const double x, const double y) {
    import std.math: sqrt;
    auto radius = sqrt(x * x + y * y);
    if (radius <= 1)
        return 10;
    if (radius <= 5)
        return 5;
    if (radius <= 10)
        return 1;
    return 0;
}

unittest
{
    immutable int allTestsEnabled = 1;

    // A dart lands outside the target
    assert(score(-9, 9) == 0);

    static if (allTestsEnabled)
    {
        // A dart lands just in the border of the target
        assert(score(0, 10) == 1);

        // A dart lands in the outer circle
        assert(score(4, 4) == 1);

        // A dart lands right in the border between outer and middle circles
        assert(score(5, 0) == 5);

        // A dart lands in the middle circle
        assert(score(0.8, -0.8) == 5);

        // A dart lands right in the border between middle and inner circles
        assert(score(0, -1) == 10);

        // A dart lands in the inner circle
        assert(score(-0.1, -0.1) == 10);

        // A dart whose coordinates sum to > 1 but whose radius to origin is <= 1 is scored in the inner circle
        assert(score(0.4, 0.8) == 10);

        // A dart whose coordinates sum to > 5 but whose radius to origin is <= 5 is scored in the middle circle
        assert(score(2, 4) == 5);

        // A dart whose coordinates sum to > 10 but whose radius to origin is <= 10 is scored in the outer circle
        assert(score(4, 8) == 1);
    }
}
