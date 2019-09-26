module perfect_numbers;
debug(2) import std.stdio;

immutable int expOnly = 1;
immutable int primeFactorsOnly = 1;
immutable int everything = 1;

enum Classification
{
    DEFICIENT,
    PERFECT,
    ABUNDANT
}

// foldr f z []     = z
// foldr f z (x:xs) = x `f` foldr f z xs
S foldr(T, S)(S function(T, S) f, S z, T[] rest) {
    return (rest.length == 0) ? z : f(rest[0], foldr(f, z, rest[1..$]));
}
//powerSet = foldr (\x acc -> acc ++ map (x:) acc) [[]]
T[][] powerset(T)(T[] set) {
    import std.algorithm;
    import std.array;
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
    //debug(3) readf("\n");
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
    // 16,  2 => 2^2, 2^3, 2^4, 2^5 XX
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
// An helper method for using the partial results given by Pollard's rho algorithm to find out the 
// rest of the factors of the number.
//
// After running Pollard's rho, we have a list of semi-random factors, at least 1, 
// and not necessarily prime, from which we should build the full list.
// The surest way is to use these known factors to build the list of only prime factors,
// and then use the power set of this list to build the full list of factors.
//
// Say the number n decomposes into the following prime factors:
// n = a^6 * b^3 * c * d
// and say that in from Pollard's rho algorithm we only found the factor: 
// f0 = a^5*b^2
// from which we should obtain the rest of them.
// 1) Take successively the i-th root of f0 until we get just a, or <1.
//    1.1) If e.g. f0 = a^5*b^2, then we won't get any root, then it's not a prime factor power, 
//         and we should decompose it further:
//         Run Pollard's rho algorithm on this number, and repeat step (1) on the factor we find.
//    1.2) If e.g. f0 = a^5, then we do get a root. Raise f0 by this root until we get 
//         the highest factor of n. 
//         Also keep f0's root and its multiplicity.
//    1.3) NOTE: Pollard's rho may give us several factors, in which case we can speed up the
//         factorization by repeating (1) on each factor before moving to step (2)
// 2) If we found a prime factor, say a, where a^6 is the highest exponent:
//    Divide n by this:  n = n / a^6  (== b^3 * c * d, but we don't know it yet).
//    2.1) If at step (1) we found several factors from Pollard's rho, divide n by their product,
//         speeding up the factorization.
// 3) Repeat step 1 on n.
// 4) Stop when n is prime (i.e. Pollard's rho gives us no factors).
T[] GetPrimeFactors(T)(T n) {
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

    while (n > 1) {
        auto factorFromPollard = factorWithPollardsRho(n);

        if (factorFromPollard.isNull) { // n is prime
            if (n != originalN) {
                primeFactors ~= n;
            }
            break;
        }
        else {
            bool keepFactoringFactor = true;
            while(keepFactoringFactor) {
                auto f = factorFromPollard.get;
                // To find out if "f" is of the form p^x (where p is presumably a prime, since that's what Pollard's
                // rho algorithm is supposed to give us):
                // Calculate the roots f^(1/exp), , where: exp=2..max , and f^(1/max) is not a whole number
                auto isExponentResult = isExponent(f);

                // The result of running isExponent on the factor f can be either (a, b, c are prime factors):
                // a
                // a*a*a*...
                // a*a*b*c....
                // 
                // a*a*a* .. => We know for sure this is an exponent of a prime factor
                // But we can't distinguish between a and a*a*b*c*...
                // In that case, we send it to Pollard's. 
                // If it finds no factors then it's a (that is, a is prime), then we can put it in the known factors 
                // just once and divide n by it.
                // If it does find factors then f is a*a*b*c.. 
                if (isExponentResult.isExp) {
                    auto highestExponent = HighestExponent(isExponentResult.base, n);
                    appender(&primeFactors) ~= isExponentResult.base.repeat(highestExponent);
                    n /= isExponentResult.base ^^ highestExponent;
                    keepFactoringFactor = false;
                } else {
                    // It's either a prime factor, or a product of some combination of such.
                    auto factorOfFactor = factorWithPollardsRho(f);
                    if (factorOfFactor.isNull) {
                        // f is prime, but is there f^x that is also a factor?
                        auto highestExponent = HighestExponent(f, n);
                        appender(&primeFactors) ~= f.repeat(highestExponent);
                        n /= f ^^ highestExponent;
                        keepFactoringFactor = false;
                    } else {
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
        GetPrimeFactors(2).should.equal([2]);

        GetPrimeFactors(10).sort.should.equal([2, 5]);
        GetPrimeFactors(8).sort.should.equal([2, 2, 2]);
        GetPrimeFactors(15).sort.should.equal([3, 5]);
        GetPrimeFactors(16).sort.should.equal([2, 2, 2, 2]);
        GetPrimeFactors(2*2*2*3*3*3).sort.should.equal([2, 2, 2, 3, 3, 3]);
        GetPrimeFactors(7).sort.should.equal(cast(int[])([]));
        GetPrimeFactors(9973).sort.should.equal(cast(int[])([]));
        GetPrimeFactors(9971).sort.should.equal([13, 13, 59]);

        GetPrimeFactors(13*59*2677).sort.should.equal([13, 59, 2677]);
        GetPrimeFactors(31*857*2153).sort.should.equal([31, 857, 2153]);
        GetPrimeFactors(2*7*5843*9479).sort.should.equal([2, 7, 5843, 9479]);
        GetPrimeFactors(33_550_336uL).sort.should.equal([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8191]);
        GetPrimeFactors(2*3*3*3*5*5*7*7*7*17).sort.should.equal([2,3,3,3,5,5,7,7,7,17]);
        GetPrimeFactors(19267uL*17291uL*17291uL).sort.should.equal([17291uL,17291uL,19267uL]);
    }
}

import std.typecons: Nullable, nullable;
// https://en.wikipedia.org/wiki/Pollard%27s_rho_algorithm
Nullable!T factorWithPollardsRho(T)(T n) {
    import std.numeric: gcd;
    import std.math: abs, pow;
    import std.algorithm: canFind;

    // Polynomial for Pollard's rho, see Wikipedia article above.
    auto g = (T x) => (x*x + 1) % n;
    // I'm using n^1/3 as an upper bound, slightly larger than the heuristic, which is n^1/4.
    // Running some iterations I saw that this increased the odds of finding at least 2 factors.
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

Classification classify(T)(T n) {
    import std.algorithm;
    import std.range;
    import std.exception;
    //debug(3) readf("\n");
    enforce(n > 0, "n must be a natural number");

    auto primeFactors = GetPrimeFactors(n);
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

static if (everything) {
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