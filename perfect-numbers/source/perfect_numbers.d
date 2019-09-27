module perfect_numbers;
debug(2) import std.stdio;

immutable int expOnly = 0;
immutable int primeFactorsOnly = 0;
immutable int justPerfectNumbers = 1;

// Power set implementation: 
// I copied Haskell's implementation of a power set and tried to implement it in D.
// I also added this to Rosetta Code section on D's implementation of the algorithm.
// D doesn't have foldr, so I copied its (naive) implementation from Haskell
//
// Haskell code:
// foldr f z []     = z
// foldr f z (x:xs) = x `f` foldr f z xs
S foldr(T, S)(S function(T, S) f, S z, T[] rest) {
    return (rest.length == 0) ? z : f(rest[0], foldr(f, z, rest[1..$]));
}
// Haskell code:
//powerSet = foldr (\x acc -> acc ++ map (x:) acc) [[]]
T[][] powerset(T)(T[] set) {
    import std.algorithm;
    import std.array;
    // The types for x and acc in the lambda below aren't actually needed, but I felt
    // it makes the code a bit clearer.
    return foldr( (T x, T[][] acc) => acc ~ acc.map!(accx => x ~ accx).array , [[]], set );
}

import std.typecons;
import std.traits: isIntegral;
alias IsExponentResult(T) = Tuple!(bool, "isExp", T, "base", T, "exponent");
// If n = p^x, return (true, p, x).  
// If n is not in the form p^x, including the case where n is prime, return (false, 0, 0)
IsExponentResult!T isExponent(T)(in T n) if (isIntegral!T)
{
    // 16 -> 16^1/2, .. 16^1/4=0 ** , 16^1/5 < 2 stop
    // 3  -> 3^1/2 <2 stop, 
    // 6  -> 6^1/2, 6^1/3 < 2 stop
    // 59 -> (prime) 59^1/2 ..., 59^1/7 < 2 stop

    import std.math;
    double rootBase = n;
    double prevRootBase = n;
    ulong  rootExp = 1;
    ulong  prevExp = 1;
    bool found = false;
    while(rootBase > 2) {
        rootExp += 1;
        rootBase = pow(cast(double)n, cast(double)(1.0 / rootExp));
        if(abs(trunc(rootBase) - rootBase) < 1e-20) {
            found = true;
            prevRootBase = rootBase; 
            prevExp = rootExp;
        }
    }
    return IsExponentResult!T(found,
                              (found) ? cast(T)prevRootBase : 0, 
                              (found) ? cast(T)prevExp : 0);
}

static if (expOnly) {
unittest {
    import dshould;
    isExponent(2).should.equal(IsExponentResult!int(false, 0, 0));
    isExponent(16).should.equal(IsExponentResult!int(true, 2, 4));
    isExponent(3).should.equal(IsExponentResult!int(false, 0, 0));
    isExponent(4).should.equal(IsExponentResult!int(true, 2, 2));
    isExponent(7).should.equal(IsExponentResult!int(false, 0, 0));
    isExponent(67108864uL).should.equal(IsExponentResult!int(true, 2, 26));
    isExponent(67108865uL).should.equal(IsExponentResult!int(false, 0, 0));
    isExponent(67108863uL).should.equal(IsExponentResult!int(false, 0, 0));
}
}

// Assuming factor divides n, find out the max exp where factor^exp divides n.
T HighestExponent(T)(T factor, T n) if (isIntegral!T) {
    import std.range;
    import std.algorithm;
    if (n == 2)
        return 1;
    // i=factor..x until n%(factor^i) != 0
    auto result = iota(2, n).until!(x => n % (factor ^^ x) != 0).tail(1);
    return (result.empty) ? 1 : result.front;
}

static if (expOnly) {
unittest {
    import dshould;
    HighestExponent(2, 2).should.equal(1);
    HighestExponent(2, 16).should.equal(4);
    HighestExponent(3, 2*2*2*3*3*3*3*3).should.equal(5);
    // 201326592 = 2^26 * 3
    HighestExponent(2, 201326592).should.equal(26);
    HighestExponent(3, 201326592).should.equal(1);
}
}

// Given n, find a factor of it using the Pollard's rho semi-probabilistic algorithm.
// If Pollard's rho doesn't find a factor, an empty Nullable will be returned.
// Note that the factor returned by this method may not be prime.
// https://en.wikipedia.org/wiki/Pollard%27s_rho_algorithm
import std.typecons: Nullable;
Nullable!T factorWithPollardsRho(T)(T n) if (isIntegral!T) {
    import std.numeric: gcd;
    import std.math: abs, pow;
    import std.algorithm: canFind;
    import std.typecons: nullable;

    // Polynomial for Pollard's rho, see Wikipedia article above.
    auto g = (T x) => (x*x + 1) % n;
    // I'm using n^1/3 as an upper bound, slightly larger than the heuristic, which is n^1/4.
    // Running some iterations I saw that this increased the odds of finding a factor.
    // According to wikipedia: 
    // If the pseudorandom number x = g ( x ) occurring in the Pollard ρ algorithm were an actual random number, 
    // it would follow that success would be achieved half the time, by the Birthday paradox in 
    // O ( p ) ≤ O ( n ^ 1/4 ) iterations. 
    // It is believed that the same analysis applies as well to the actual rho algorithm, but 
    // this is a heuristic claim, and rigorous analysis of the algorithm remains open.
    const uint maxIterationsWithoutNewFactor = cast(uint)pow(n, 1.0/3);
    uint maxCycles = 2;
    uint noNewFactorIteration = 0;
    T x0 = 2, y0 = 2, d0 = 1;

    // NOTE: This could be made much faster: it doesn't use Brent's variant of the algorithm
    // (see wikipedia article referneced above)
    while(noNewFactorIteration < maxIterationsWithoutNewFactor) {
        auto x = x0, y = y0, d = d0;
        uint cycles = 0;
        while(d == 1 && ++cycles <= maxCycles) {
            x = g(x);
            y = g(g(y));
            d = gcd(abs(x - y), n);
        }
        auto foundFactor = d != n && d != 1;
        if (foundFactor) {
            return nullable(d);
        }
        //debug(2) if (foundNewFactor) writeln(n, ' ', d, ' ', foundFactor, ' ', foundNewFactor, ' ', factors, ' ', cycles, ' ', x0, ' ', y0, ' ', maxCycles, ' ', noNewFactorIteration);

        if (!foundFactor) {
            noNewFactorIteration += 1;
            maxCycles = noNewFactorIteration % 100 + 2;
        }
        // It's a failure and we need to restart with other values
        // Picking new starting x0 here was done heuristically, I played around and saw that this 
        // increased the odds of finding a factor sooner.
        x0 = (y0 + noNewFactorIteration) % n;
        y0 = x0;
    }
    return Nullable!T();
}

// Given a number n, returns a all its prime factors, with multiplicity.
// If n is prime, an empty list will be returned.
// If n has a prime factor that divides it, return this factor in the list in the number
// of times it divides n.
T[] getPrimeFactors(T)(T n) {
    import std.math;
    import std.range;
    import std.algorithm;
    import std.typecons;

    const originalN = n;
    T[] primeFactors;
    // Pollard's rho doesn't give very good results with even inputs, so first
    // get rid of all factors that are powers of 2 (if any).
    // See https://math.stackexchange.com/questions/2855796/bad-numbers-for-pollard-rho-algorithm
    if (n % 2 == 0) {
        auto highestExponent = HighestExponent(2, n);
        appender(&primeFactors) ~= 2.repeat(highestExponent);
        n /= 2 ^^ highestExponent;
    }

    // After running Pollard's rho, we have a factor of n.
    // This factor is not necessarily prime, but we can use it to get the full factor list.
    // Say the number n decomposes into the following prime factors:
    // n = a^6 * b^3 * c * d
    // (It always should, see Fundamental theorem of arithmetic, https://en.wikipedia.org/wiki/Fundamental_theorem_of_arithmetic)
    // Since Pollard's rho is probabilistic, it can give us a factor of the following forms:
    // (1) f = a^3
    // OR
    // (2) f = a
    // OR
    // (3) f = a^5*b^2
    // To get the rest of them, we should find out which case it is.
    // 1) If it's (1), that is, f=p^x, we can discover this by taking the i-th root of f until we get 
    //    1 or p itself. This is done by the function isExponent.
    //    This is (roughly) O(log(n)) operation, much faster than using Pollard's rho.
    //    After we've found p, we should check what is the highest exponent it divides n by.
    //    In the example above:   we got f=a^3, but we want to find a^6.
    //    This is done with HighestExponent.
    //    Then we add x times the prime factor p to the list of factors.
    //    Then we divide n by this number with the highest exponent to get rid of it completely.
    // 
    // 2) If it's (2), that is, f = p , we can discover this by running Pollard's rho on f. If it finds
    //    no factors then f is prime (with a high degree of probability...).
    //    In this case we again want to find what is the highest exponent it divides n by.
    //    In the example above:   we got f=a, but we want to find a^6.
    //    This is also done with HighestExponent.
    //    Then we add x times the prime factor p to the list of factors.
    //    Then we divide n by this number with the highest exponent to get rid of it completely.
    //
    // 3) If it's (3), that is, f is a a product of some factors raised by some exponents,
    //    we discover by running Pollard's rho on f and it finds some factors.
    //    In this case, keep calling Pollard's rho on f until it gives us a sub-factor of it,
    //    that is case (1) or case (2).
    // 
    // Stop conditions: 
    // Since we divide n by its prime factor with multiplicity every step, we stop when we get to 1,
    // or when we get n which is prime.

    while (n > 1) {
        auto factorFromPollard = factorWithPollardsRho(n);

        if (factorFromPollard.isNull) { // n is prime
            if (n != originalN) { // If this is the original n, then n itself is prime, we shouldn't add it to the results.
                primeFactors ~= n;
            }
            break;
        }
        else {
            bool keepFactoringFactor = true;
            // Keep calling Pollard's rho on f until we get f=p^x or f=p (where p is prime)
            while(keepFactoringFactor) { 
                auto f = factorFromPollard.get;
                // To find out if "f" is of the form p^x (where p is presumably a prime, since that's what Pollard's
                // rho algorithm is supposed to give us):
                // Calculate the roots f^(1/exp), , where: exp=2..max , and f^(1/max) is not a whole number
                auto isExponentResult = isExponent(f);

                if (isExponentResult.isExp) {
                    // Case (1) from above - f = p^x
                    auto highestExponent = HighestExponent(isExponentResult.base, n);
                    appender(&primeFactors) ~= isExponentResult.base.repeat(highestExponent);
                    n /= isExponentResult.base ^^ highestExponent;
                    keepFactoringFactor = false;
                } else {
                    // It's either a prime factor, or a product of some combination of such.
                    // Find out by running Pollard's rho again on it.
                    auto factorOfFactor = factorWithPollardsRho(f);
                    if (factorOfFactor.isNull) {
                        // Case (2) above.
                        // f is prime, but is there f^x that is also a factor?
                        auto highestExponent = HighestExponent(f, n);
                        appender(&primeFactors) ~= f.repeat(highestExponent);
                        n /= f ^^ highestExponent;
                        keepFactoringFactor = false;
                    } else {
                        // Case (3) above.
                        // It's a combinations of product of some primes, keep factoring it.
                        factorFromPollard = factorOfFactor.get;
                    }
                }
            }
        }
    }
    return primeFactors;
}

static if (primeFactorsOnly) {
    unittest {
        import dshould;
        import std.stdio;
        import std.algorithm;
        import std.array;
        import std.conv;
        //debug(3) readf("\n");
        getPrimeFactors(2).should.equal([2]);
        
        getPrimeFactors(10).sort.should.equal([2, 5]);
        getPrimeFactors(8).sort.should.equal([2, 2, 2]);
        getPrimeFactors(15).sort.should.equal([3, 5]);
        getPrimeFactors(16).sort.should.equal([2, 2, 2, 2]);
        getPrimeFactors(2*2*2*3*3*3).sort.should.equal([2, 2, 2, 3, 3, 3]);
        getPrimeFactors(7).sort.should.equal(cast(int[])([]));
        getPrimeFactors(9973).sort.should.equal(cast(int[])([]));
        getPrimeFactors(9971).sort.should.equal([13, 13, 59]);
        
        getPrimeFactors(13*59*2677).sort.should.equal([13, 59, 2677]);
        getPrimeFactors(31*857*2153).sort.should.equal([31, 857, 2153]);
        getPrimeFactors(2*7*5843*9479).sort.should.equal([2, 7, 5843, 9479]);
        getPrimeFactors(33_550_336uL).sort.should.equal([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8191]);
        getPrimeFactors(2*3*3*3*5*5*7*7*7*17).sort.should.equal([2,3,3,3,5,5,7,7,7,17]);
        getPrimeFactors(19267uL*17291uL*17291uL).sort.should.equal([17291uL,17291uL,19267uL]);
    }
}


enum Classification
{
    DEFICIENT,
    PERFECT,
    ABUNDANT
}

Classification classify(T)(T n) {
    import std.algorithm;
    import std.range;
    import std.exception;
    enforce(n > 0, "n must be a natural number");

    auto primeFactors = getPrimeFactors(n);
    auto allFactors = primeFactors.powerset[1..$] // Filter the first empty subset
        .map!(fold!((prev, x) => prev * x)) // For each subset, multiply all its members
        .chain([1]) // Add 1 
        .array.sort.uniq.array;

    auto sum = allFactors.filter!(x => x < n).sum;
    with(Classification) {
        if (sum == n)
            return PERFECT;
        if (sum > n)
            return ABUNDANT;
        return DEFICIENT;
    }
}

static if (justPerfectNumbers) {
unittest
{
    import std.exception : assertThrown;

    immutable int allTestsEnabled = 1;

    // Perfect numbers

    // Smallest perfect number is classified correctly
    assert(classify(6) == Classification.PERFECT);

    // Medium perfect number is classified correctly
    assert(classify(28) == Classification.PERFECT);

    // Large perfect number is classified correctly
    assert(classify(33_550_336) == Classification.PERFECT);

    static if (allTestsEnabled)
    {
        // Abundant numbers

        // Smallest abundant number is classified correctly
        assert(classify(12) == Classification.ABUNDANT);

        // Medium abundant number is classified correctly
        assert(classify(30) == Classification.ABUNDANT);

        // Large abundant number is classified correctly
        assert(classify(33_550_335) == Classification.ABUNDANT);

        
        // Deficient numbers

        // Smallest prime deficient number is classified correctly
        assert(classify(2) == Classification.DEFICIENT);

        // Smallest non-prime deficient number is classified correctly
        assert(classify(4) == Classification.DEFICIENT);

        // Medium deficient number is classified correctly
        assert(classify(32) == Classification.DEFICIENT);

        // Large deficient number is classified correctly
        assert(classify(33_550_337) == Classification.DEFICIENT);

        // Edge case (no factors other than itself) is classified correctly
        assert(classify(1) == Classification.DEFICIENT);

        
        // Invalid inputs

        // Zero is rejected (not a natural number)
        assertThrown(classify(0));

        // Negative integer is rejected (not a natural number)
        assertThrown(classify(-1));
    }

}
}