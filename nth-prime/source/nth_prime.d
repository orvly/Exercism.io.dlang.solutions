module nth_prime;

import std.bigint;

//// TODO: Arbitrary sized primes
//BigInt prime(BigInt nth) {
//}
ulong prime(ulong nth) {
    // Goal: Compute nth prime for arbitrarily large n.
    // Method: Segmented sieve of Erastothenes.
    //
    // nth prime is about n*ln(n), but might be slightly higher.
    // https://en.wikipedia.org/wiki/Prime_number_theorem#Approximations_for_the_nth_prime_number
    // To use a sieve, we need at least this much bits.
    // We have BitArray, but its size is limited to ulong...
    // Maybe we can have a streaming BitArray?
    // Once we marked all numbers, we move the window forwards.
    // BUT - we have to keep marking all multiples of previous primes too...
    // So we have to keep all previous primes, for that again we need nln(n) array...
    // Perhaps save it to disk, that is, when we decide to move the window of the BitArray,
    // read (possibly from the disk) all previous primes, and mark all known multiples in the BitArray
    // window.
    // 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
    // 1 2 x 3 x 4 x x
    //
    // State:
    // NumberOfCurrentPrime 
    // StartOfWindow, EndOfWindow
    //
    // In Memory+Disk:
    // List of found primes.
    // Algorithm:
    //  Divide the range 2 through n into segments of some size Δ ≤ √n.
    //  Find the primes in the first (i.e. the lowest) segment, using the regular sieve.
    //  For each of the following segments, in increasing order, with m being the segment's topmost value, 
    //  find the primes in it as follows:
    //      Set up a Boolean array of size Δ, and
    //      Eliminate from it the multiples of each prime p ≤ √m found so far, by calculating 
    //      the lowest multiple of p between m - Δ and m, and enumerating its multiples in steps of p as usual, 
    //      marking the corresponding positions in the array as non-prime.
    //
    // Can we parallelize this? Spread segments between cores. Each core can start with the known primes, 
    // and then pick up the rest of the primes found (if any) when any other core finishes. It's finished
    // with its segment when all previous segments are finished.
    // 
    //
    // Detemine size of segment based on free physical memory.
    // OR: Size of L2 cache? In my computer, L1=16KB, L2=128KB=2^7*2*10=2^17 bytes
    // But we also need to check against known primes, we need to keep at least some of them in memory,
    // we can decide to keep the smaller ones always in the L2 and read the rest from memory/disk.
    // (Can use memory mapped file).
    // So:  since we require passing over the bit array twice (second time to find the unmarked ones == primes)
    // we will need to keep both primes and the bit array in memory as much as possible.
    // So:  say half the space (2^16 bytes) for small prime numbers, and half (2^16 bytes) for the bit array.

    import std.container.array: Array;
    import std.range: iota, back, drop;
    import std.algorithm: each, countUntil;
    import std.exception: enforce;
    
    enforce(nth > 0, "illegal input");

    const L1Size = 16 * (1 << 10); // TODO: Get it from current machine
    // Put the flags (bitset) in the L1
    auto isPrime = Array!bool();
    isPrime.length = L1Size * 100;
    // Put the first known primes in L2, if we have a multi-core algorithm they can share it.
    const L2Size = 128 * (1 << 10); // TODO: Get it from current machine
    ulong[] knownPrimes;
    knownPrimes.reserve = L2Size;
    knownPrimes ~= 2;

    // TODO: Sliding segment
    //size_t startBitIndex = 0;
    //size_t endBitIndex = startBitIndex + isPrimeBits.length;
    // Step 1 for each segment: Fill knownPrimes, by iterating over them, and filling them as we go,
    // until we've filled the whole length of knownPrimes, or we reach out number.
    // Use isPrimeBits to do that by marking things there.
    //knownPrimes.each!(p => iota(p, isPrime.length, p).each!(n => isPrime[n] = true));

    size_t nthSizet = nth;
    debug(3) import std.stdio;
    debug(3) readf("\n");
    while(knownPrimes.length < nthSizet) {
        // Step 1: Fill knownPrimes, by iterating over them, and filling them as we go
        const lastKnownPrime = knownPrimes[$ - 1];
        // Start marking out with lastKnownPrime ^^ 2, multiples below that have factors that were already
        // removed.
        iota(lastKnownPrime ^^ 2, isPrime.length, lastKnownPrime).each!(n => isPrime[n] = true);
        // Step 2: Find first unmarked bit and add its corresponding index to knownPrimes.
        // Repeat.
        const nextPrimeIndex = isPrime[].drop(lastKnownPrime + 1).countUntil(false) + lastKnownPrime + 1;
        assert(nextPrimeIndex > lastKnownPrime);
        knownPrimes ~= nextPrimeIndex;
    }
    return knownPrimes[$ - 1];
}
// TODO: Also implement the equivalent functional algorithm:
//   primes = [2, 3, ...] \ [[p², p²+p, ...] for p in primes],
// (From https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes#Incremental_sieve)

auto primesGen(size_t nth) {
    import std.algorithm;
    import std.range;

    auto infIota(T) = (T start) { T i = start; return generate!(() => i++); };
    //return infIota!int(2).zip(infIota!int(3));

    //int j;
    //auto primes1 = generate!(() => i += 1);
    // primes1.enumerate -> 0,2, 1,3, 2,4,  3, 5, ...
    // 0,2 -> 4,6,8,
    // 1,3 -> 9,12,15,
    //auto temp = primes1.enumerate.map!(t => generate!(() => t.value^^2 + t.index * t.value));
    //auto f = iota(1, 1);
    //auto mults = generate!;
    //auto primes_ = infIota!int(2).setDifference(mults).take(nth);
    //auto mults_ = primes_.map!(n => infIota!int(0).map!(j => n^^2 + j*n)).joiner;

    auto primes1 = infIota!int(2);
    auto primes2 = infIota!int(2).map!(n => infIota!int(0).map!(j => n^^2 + j*n)).joiner;
    auto primes3 = primes1.setDifference(primes2);
    return primes3;
    //auto primes3 = primes1.setDifference(primes2);
    
    //auto r2 = generate!(() => j += 3);
    //auto r1 = generate!(() => i += 2);
    //auto result = r2.setDifference(r1);
    //return result;
    //primes ~= primes.setDifference(primes.each!( (i, p) => generate!(() => p^^2 + i*p) ));
}

unittest {
    import std.stdio;
    import std.algorithm;
    import std.range;
    auto test1 = primesGen(10);
    writeln(test1.take(10));
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
