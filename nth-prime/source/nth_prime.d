module nth_prime;

ulong prime1(ulong nth) {
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

ulong prime(const ulong nth) {
    import vibe.http.client;
    import vibe.stream.operations;
    import std.conv;
    import std.regex;
    import std.algorithm;
    import std.string;
    import std.exception: enforce;

    enforce(nth > 0, "illegal input");

    ulong p;
    void handleResponse(scope HTTPClientResponse resp) {
        auto reader = resp.bodyReader;
        auto r = regex(`\d+`, "g");
        foreach(i; 0..4) { // Skip heading - first 4 lines
            reader.readLine;
        }
        uint num = 0;
        while(!reader.empty) {
            // assumeUTF converts to a string
            auto line = reader.readLine.assumeUTF;
            auto matches = line.matchAll(r);
            // matches is a lazy range, so we also need a function that both knows where to stop
            // iterating, AND returns the value of the place where we stopped.  find() is such
            // a function, but we misuse it here, we aren't really interested in finding anything,
            // just using it as a loop, so the actual start and values don't matter.
            // We could have also used each() which is the more correct function in this case,
            // but that would actually be more cumbersome to write...

            // BUG: If "num" isn't defined, then the following line will fail to compile,
            //      but with the wrong error message about a mismatching template instead of "unknown symbol".
            auto found = matches.find!((_,__) => ++num == nth)(typeof(matches.front).init);
            // find() returns a sub-range which starts at the found location, so we
            // just have to use front() on it to get to the match itself.
            // hit() is used to get the actual text.
            if (!found.empty) {
                p = found.front.hit.to!ulong;
                break;
            }
        }
    }
    requestHTTP("https://primes.utm.edu/lists/small/100000.txt",
                (scope req) {
                    req.method = HTTPMethod.POST;
                },
                &handleResponse);
    return p;
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
