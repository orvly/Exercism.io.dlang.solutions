module nth_prime;

ulong prime(ulong nth) {
    // Method: Sieve of Erastothenes.

    import std.container.array: Array;
    import std.range: iota, drop;
    import std.algorithm: each, countUntil;
    import std.exception: enforce;
    import std.math: log, ceil;
    import std.conv: to;

    enforce(nth > 0, "illegal input");

    auto isPrime = Array!bool();
    // nth prime is about n*ln(n), but might be slightly higher.
    // https://en.wikipedia.org/wiki/Prime_number_theorem#Approximations_for_the_nth_prime_number
    // To use a sieve, we need at least this much bits.
    isPrime.length = (nth * log(nth) * 1.2).ceil.to!size_t + 2;

    ulong curPrimeIndex = 0;
    ulong lastKnownPrime = 2;
    while((curPrimeIndex += 1) < nth) {
        // Step 1: Fill knownPrimes, by iterating over them, and filling them as we go
        // Start marking out with lastKnownPrime ^^ 2, multiples below that have factors that were already
        // removed.
        iota(lastKnownPrime ^^ 2, isPrime.length, lastKnownPrime).each!(n => isPrime[n] = true);
        // Step 2: Find first unmarked bit and add its corresponding index to knownPrimes.
        // [] must be used on isPrime to turn it into a range.
        lastKnownPrime = isPrime[].drop(lastKnownPrime + 1).countUntil(false) + lastKnownPrime + 1;
    }
    return lastKnownPrime;
}

unittest
{
    import std.exception : assertThrown;

    immutable int allTestsEnabled = 1;
    // first prime
    assert(prime(1) == 2);

    static if (allTestsEnabled)
    {
        // second prime
        assert(prime(2) == 3);

        // sixth prime
        assert(prime(6) == 13);
        // big prime
        assert(prime(10_001) == 10_4743);

        // there is no zeroth prime
        assertThrown(prime(0));
    }

}
