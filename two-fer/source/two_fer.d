module two_fer;

string twoFer(string name = null) {
    import std.format: format;
    return format!"One for %s, one for me."( (name == null) ? "you" : name);
}

unittest
{
    immutable int allTestsEnabled = 1;

    // no name given
    assert(twoFer() == "One for you, one for me.");

    static if (allTestsEnabled)
    {
        // a name given
        assert(twoFer("Alice") == "One for Alice, one for me.");

        // another name given
        assert(twoFer("Bob") == "One for Bob, one for me.");
    }

}
