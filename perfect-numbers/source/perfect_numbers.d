module perfect_numbers;
debug(2) import std.stdio;

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

// knownFactors might include 1 and the number itself
T[] allFactors(T)(T[] knownFactors, T n) {
    import std.algorithm;
    import std.array;
    import std.range;

    return knownFactors
        .filter!(g => g != 1 && g != n)
        .array
        .powerset[1..$] // Filter the first empty subset
        // For each subset, multiply all its members
        .map!(fold!((prev, x) => prev * x))
        .chain([1, n])
        .array.sort.uniq.array;
}


class Set(T) {
private: 
    bool[T] _d; // bool is a dummy value type, we only care about the keys
public:
    bool opBinaryRight(string op)(T val) if (op == "in") {
        return *(val in _d);
    }
    bool add(T val) {
        auto exists = val in _d;
        _d[val] = true;
        return !exists;
    }
    bool remove(T val) {
        return _d.remove(val);
    }
    T[] array() {
        return _d.keys;
    }
}
T popBackVal(T)(T[] a) {
    import std.range;
    T last = a.back;
    a.popBack();
    return last;
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
T[] GetPrimeFactors(T)(T[] factorsToCheck, T n) {
    import std.math;
    import std.range;
    T[] primeFactors;
    Set!T knownFactors;
    while(factorsToCheck.length > 0)
    {
        auto f = factorsToCheck.popBackVal;
        if (f in knownFactors) {
            continue;
        }
        // To find out if "f" is of the form p^x (where p is presumably a prime, since that's what Pollard's
        // rho algorithm is supposed to give us):
        // Calculate the roots f^(1/exp), exp=2..max , where: f^(1/max) is not a whole number
        //double fReal = f;
        double prev = f;
        double next = f;
        ulong rootExp = 1;
        while(next > 1 && trunc(next) == next) {
            rootExp += 1;
            prev = next;
            next = pow(f, 1.0 / rootExp);
        }
        if (next <= 1) {
            // This factor is a composite of several prime exponents, not p^x, We need to decompose it further.
            // Use Pollard's rho on it.
            factorsToCheck ~= factor(f);
        } else {
            T primeFactor = cast(T)(prev);
            // This factor is a prime or an exponent of a prime.
            // Save this factor with full multiplicity in the known primeFactors, it will be used
            // later to calculate combinations of all factors.
            appender(&primeFactors) ~= primeFactor.repeat(rootExp - 1);
            // Add it and all of its exponents to the list of known factors so we won't check them
            // again if Pollar's rho gets them again.
            T factorExp = primeFactor;
            T prevFactorExp = primeFactor;
            auto powerExp = 2;
            while(n % factorExp == 0) {
                knownFactors.add(factorExp);
                prevFactorExp = factorExp;
                factorExp = pow(primeFactor, powerExp);
                powerExp += 1;
            }
            n /= prevFactorExp;
            factorsToCheck ~= n;
        }
    }
    return primeFactors;
}

// https://en.wikipedia.org/wiki/Pollard%27s_rho_algorithm
T[] factor(T)(T n) {
    import std.numeric: gcd;
    import std.math: abs, pow;
    import std.algorithm: map, fold, sort, uniq;
    import std.range: chain;
    import std.array: array;

    Set!T factorsSet;
    T[] factors = [1, n];
    auto g = (T x) => (x*x + 1) % n; // Polynomial used
    // Experimental evidence: I needed at most n^1/3 iterations to find all factors
    // using the naive Pollard Rho method below.
    const uint maxIterationsWithoutNewFactor = cast(uint)pow(n, 1.0/3);
    uint maxCycles = 2;
    uint noNewFactorIteration = 0;
    T x0 = 2, y0 = 2, d0 = 1;
    debug(3) readf("\n");
    while(noNewFactorIteration < maxIterationsWithoutNewFactor) {
        auto x = x0, y = y0, d = d0;
        uint cycles = 0;
        while(d == 1 && ++cycles <= maxCycles) {
            x = g(x);
            y = g(g(y));
            d = gcd(abs(x - y), n);
        }
        auto foundFactor = d != n;
        auto foundNewFactor = false;
        if (foundFactor) {
            foundNewFactor = factorsSet.add(d);
        }
        debug(2) if (foundNewFactor) writeln(n, ' ', d, ' ', foundFactor, ' ', foundNewFactor, ' ', factors, ' ', cycles, ' ', x0, ' ', y0, ' ', maxCycles, ' ', noNewFactorIteration);
        if (!foundFactor || !foundNewFactor) {
            noNewFactorIteration += 1;
            maxCycles = noNewFactorIteration % 100 + 2;
        }
        // 2 possible cases here:
        // 1) If d == n then it's a failure and we need to restart with other values
        // 2) If d != n then we (possibly) found a factor, and we need to look for other factor.
        x0 = (y0 + noNewFactorIteration) % n;
        y0 = x0;
    }
    auto primeFactorsWithMultiplicity = GetPrimeFactors(factorsSet.array, n);
    auto allFactors = primeFactorsWithMultiplicity
        .powerset[1..$] // Filter the first empty subset
        .map!(fold!((prev, x) => prev * x)) // For each subset, multiply all its members
        .chain([1, n]) // Add 1 and n
        .array.sort.uniq.array;
    return allFactors;
}

immutable int factorOnly = 1;
immutable int everything = 0;

static if (factorOnly)
{
    unittest {
        import dshould;
        import std.algorithm;
        

        // Take all found factors
        // Keep the lowest ones
        // In case of 2_053_259:  13, 59, 767
        // Divide n by each one

        //factor(2).sort.should.equal([1, 2]);
        factor(15).sort.should.equal([1, 3, 5, 15]);
        //factor(2048).sort.should.equal(allFactors([1, 2,2,2,2,2,2,2,2,2,2,2, 2048], 2048));
        //factor(8051).sort.should.equal([1, 83, 97, 8051]);
        //factor(8257).sort.should.equal([1, 23, 359, 8257]);
        //factor(7).sort.should.equal([1, 7]);
        //factor(9973).sort.should.equal([1, 9973]);
        //factor(9971).sort.should.equal(allFactors([1, 13, 13, 59, 9971], 9971));
        //factor(2_053_259).sort.should.equal(allFactors([1, 13, 59, 2677, 2053259], 2053259));
        //factor(57198751).sort.should.equal(allFactors([1, 31, 857, 2153, 57198751], 57198751));
        //factor(775_401_158).sort.should.equal(allFactors([1, 2, 7, 5843, 9479, 775_401_158], 775_401_158));
        //factor(33_550_336uL).sort.should.equal(allFactors([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8191], 33550336));
    }
}

Classification classify(ulong n) {
    import std.algorithm;
    import std.range;

    auto sum = factor(n).filter!(x => x < n).sum;
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

    debug(2) writeln("START");
    // Perfect numbers

    // Smallest perfect number is classified correctly
    assert(classify(6) == Classification.PERFECT);
    debug(2) writeln("TEST 2");

    // Medium perfect number is classified correctly
    assert(classify(28) == Classification.PERFECT);
    debug(2) writeln("TEST 3");

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