module rna_transcription;

static immutable char[char] translations;
// static immutable AAs can be initialized at the module level this way.
shared static this() {
    translations = [
        'G': 'C',
        'C': 'G',
        'T': 'A',
        'A': 'U',
    ];
}

string dnaComplement(string dnaStrand) pure @safe {
    import std.algorithm: map;
    import std.exception: enforce;
    import std.conv: to;
    import std.range: appender;

    // Appender is used to preallocate enough place for the returned string, since we know its length in advance 
    auto result = appender!string;
    result.reserve(dnaStrand.length);
    result ~= dnaStrand.map!( (c) {
        // When iterating on a string, c is of type dchar, so it has to be translated to a char.
        auto r = c.to!char in translations;
        // Why enforce?
        // Using simple lookup (translations[c]) does throw an exception, but the exception is
        // RangeError, which is derived from Error, and not caught by assertThrown in the unit test
        // code below.  assertThrown catches only assertions derived from Throwable.
        // So I had to use a special enforce statement which does throw a Throwable-derived exception.
        //
        // Also, I tried putting this call to enforce inside a separate "tee" call, to make this delegate
        // a bit cleaner, but it never got called, it had to be done inside this delegate.  I'm not sure why.
        // 
        enforce(r, "Illegal dna type " ~ c.to!char);
        return *r;
    });
    return result.data;
}

unittest {
import std.exception : assertThrown;

const int allTestsEnabled = 1;

    assert(dnaComplement("C") == "G");
static if (allTestsEnabled) {
    assert(dnaComplement("G") == "C");
    assert(dnaComplement("T") == "A");
    assert(dnaComplement("A") == "U");

    assert(dnaComplement("ACGTGGTCTTAA") == "UGCACCAGAAUU");

    assertThrown(dnaComplement("U"));
    assertThrown(dnaComplement("XXX"));
    assertThrown(dnaComplement("ACGTXXXCTTAA"));
}

}
