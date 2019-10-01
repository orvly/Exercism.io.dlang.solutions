module sum_of_multiples;
import std.traits;
import std.range.primitives;

debug(1) import std.stdio;

// *************************************************
// SOLUTION #1:
// Functional. The most concise one.
// However, it's also the slowest.
// Generates all sub-sequences, then filters the numbers that are the same, before summing.
//
// Time complexity:
//   O(n*upperBound*logn), where n = numbers.length
// logn - because of the sort done before filtering using uniq (I assume it's an efficient sort).
//
// Space complexity:
//   O(n*upperBound)
//
// This actually allocates a lot (once for every subset, and once for the final joiner which joins all the subset,
// and also for the "array" call).
// So it can't be @nogc.
// *************************************************
T calculateSum1(T)(T[] numbers, T upperBound) pure
if (isIntegral!T) {
    import std.range;
    import std.algorithm;
    return numbers
        .filter!(n => n != 0)
        .map!(n => iota(n, upperBound, n))
        .joiner
        .array
        // .sort is needed since uniq assumes its input is sorted.
        .sort
        .uniq
        .sum;
}

// *************************************************
// SOLUTION #2:
// Semi-functional, uses a custum range generator which jumps
// over the range of numbers once, to return only the ones
// that are multiples of the given numbers.
// The custom range uses multiple counters (one for each number) and advances 
// the minimal one at each iteration by its amount.
//
// The custom range generator doesn't assume that the input is an array
// It uses the most general conditions for input: IsInputRange, isIntegral,
// 
// Time complexity:
//   O(upperBound / min(numbers))
// Since the lowest number decides the number of steps we take.
//
// Space complexity:
//   O(numbers.length)
// Since we keep a copy of the numbers (and also this number of counters, but the 2 factor is constant)
// *************************************************

// Returns a custom range, which does the actual job of calculateSum2 below
auto productJoiner(S, T)(S baseFactors, T maxNumber)
if (isIntegral!T && isInputRange!S && is(ElementType!S == T))
{
    // Helper struct implementing a range, which returns
    // the numbers required.
    struct ProductJoiner {
        import std.algorithm;
        import std.range;

        // Current state - the set of current numbers.  
        // The minimal number is the "front" one.
        // 
        // Each iteration of this range advances the minimal number by its
        // step from _baseFactors.
        // If several numbers are the minimal ones, we increase all of them, each one
        // by its step.
        T[] _currentNumbers; 

        const T[] _baseFactors;
        immutable T _maxNumber;
        this(S baseFactors, T maxNumber) {
            // Save the factors we've been given.
            // Ignore factors that are 0 - they shouldn't count.
            _baseFactors = baseFactors.filter!(n => n > 0).array;
            _currentNumbers = _baseFactors.dup;
            _maxNumber = maxNumber;
        }
        bool empty() const {
            return _currentNumbers.all!(n => n >= _maxNumber);
        }
        T front() const {
            return _currentNumbers.minElement;
        }
        void popFront() {
            // Advance the minimal current number by its factor.
            // Since there can be several current minimal numbers, advance all those we can find.
            // That's the way we skip over duplicates here.
            const min = _currentNumbers.minElement;
            foreach(i, ref n; _currentNumbers) {
                if (n == min) {
                    n += _baseFactors[i];
                }
            }
        }
    }
    return ProductJoiner(baseFactors, maxNumber);
}

T calculateSum2(T)(T[] numbers, T upperBound) pure 
if (isIntegral!T) {
    import std.algorithm: sum;

    return productJoiner(numbers, upperBound)
        .sum;
}

// *************************************************
// SOLUTION #3:
// Iterative (not functional) with minimal state.
// More efficient:
// * Space - it doesn't use any allocations (and is @nogc).
// * Time - Uses a formula to calculate the result instead
//          of iterating on all the numbers from 1 to upperBound.
// Uses the most general conditions for input: IsInputRange, isIntegral.
// Time complexity:
//   O(2^(numbers.length))
// Note that it doesn't depend at all on the upper bound input, as opposed to the previous
// solutions, just on the length of the given number array.
// The runtime for large inputs is dominated by the time enumerating the power set.
// Since enumerating it is basically running from 0..2^n, and for each such input running
// at most n, we get O(number.length * 2^(numbers.length)) ~= O(2^(numbers.length)).
// (This is actually a lie since the length of numbers currently can't be more than 64 due to the fact I used
// a ulong rather than an arbitrarily large bitset, for enumerating the power set, but that's the general idea...)
//
// Space complexity:
//   O(1)
// No dynamic allocations are used.
// *************************************************

// Part 1: Power Set implementation.
// Helper method the return the powerset of the given group.
// Doesn't allocate.
// Relies on the trick where enumerating the range of set bits of each number in the range 0..2^n-1
// and mapping each bit to the array index, gives us the power group.
// Has a bug where it uses a ulong to keep the number of bits, rather than an arbitrarily large 
// Returns a range of ranges, with each sub-range a sub-group of the power group of the input.
// NOTE: Each sub-range has a "length" field, even though the sub-range doesn't really implement RandomAccessRange.
//       Somehow it works...
// NOTE: I already wrote a powerSet implementation in the solution for the "perfect-numbers" problem,
//       But here I decided to write a different one, inspired by what other solutions I saw
//       that online.
auto powerSet(T, S)(S numbers) @nogc pure
if (isIntegral!T && isRandomAccessRange!S && is(ElementType!S == T))
{
    struct PowerSetRange {
        const S _numbers;
        ulong _bits;        // BUG: This should be a bitset
        ulong _maxNumBits;  // BUG: This should be a bitset
        this(S numbers) @nogc {
            // TODO: Enforce length of numbers <= 64
            _numbers = numbers;
            _bits = 0;
            _maxNumBits = 1 << numbers.length;
        }
        bool empty() @nogc { return _bits == _maxNumBits; }
        void popFront() @nogc { _bits += 1; }

        auto front() const @nogc {

            // Helper range struct which enumrates over the subset
            struct SubSetRange {
                ulong _curBits;  // BUG: This should be a bitset
                ulong _curBit;  
                const S _numbers;
                void moveToNextSetBit() @nogc {
                    while((_curBits & (1 << _curBit)) == 0 && _curBit < _numbers.length) {
                        _curBit += 1;
                    }
                }
                this(ulong bits, const S numbers) @nogc {
                    _curBits = bits; 
                    _curBit = 0;
                    _numbers = numbers;
                    moveToNextSetBit();
                }
                bool empty() @nogc { return _curBit == _numbers.length; }
                auto front() @nogc { return _numbers[_curBit]; }
                void popFront() @nogc { 
                    _curBit += 1; 
                    moveToNextSetBit(); 
                }
                size_t length() @nogc {
                    import core.bitop;
                    // The "length" is the number of bits set in the current number.
                    return _curBits.popcnt;
                }
            }
            return SubSetRange(_bits, _numbers);
        }
    }
    return PowerSetRange(numbers);
}

// Part 2: Actual sum implementation
T calculateSum3(T, S)(S numbers, T upperBound) pure @nogc nothrow
if (isIntegral!T && isRandomAccessRange!S && is(ElementType!S == T))
{
    import std.numeric: gcd;

    // The trick:
    // The sum of multiples of x up to an upper bound of max can be calculated in O(1):
    // sum of multiples:  sum = x+2x+3x+..max = x*(1+2+3+...max/x) = x * (max/x*(max/x+1)/2)
    auto sumOfMultiples = (T x, T max) => x * ((max / x) * (max / x + 1) / 2 );

    // When we get numbers x1,x2,x3... then we COULD do sum of this formula for each x,
    // BUT we need to filter out the same multiples, and for that we can calculate the sum of each product
    // of a the combination of xs, and substract it from the total xs sum.
    //
    // 1) To calculate the all the products of all combinations of numbers, we can build the power set
    // of all numbers, and then compute the product of each sub-group of length 2 or more.
    // Example: [3, 5] => 15 and 30 will appear both in 3's series sum and in 5's series sum.
    // If we calculate 15's series sum we will get them both.
    //
    // 2) However, if the numbers are not relatively prime, then the repeating number will actually
    // be their lowest common multiple.  This is also true in the general case if they're relatively prime.
    // Example:  [4, 6]  => Their LCM is 12, which will appear both in 4 and in 6 series.
    // To calculate the lowest common multiple (LCM), we can use the formula 
    // x1*x2/gcd(x1,x2).
    // See below for generalizing it for a number of inputs larger than 2.
    //
    // 3) However, this isn't enough, since for 3 numbers, this will substract the LCM of each pair too many times,
    // if it's also the LCM of all 3 numbers.
    // To compensate, we need to add BACK the LCM of all 3 numbers.
    //
    // So, The most GENERAL solution for n inputs is to go over each sub-group of the power group of the inputs,
    // and either add or substract its sumOfMultiples(groupLCM, upperBound) from the total running sum.
    
    // Why imperative style?
    // Those 2 loops below could have been handled with a functional approach, and be more succint. However 
    // using map, fold and other range function isn't possible in a @nogc function since they
    // aren't @nogc themselves, I'm using a imperative version here.
    // Currently there's the "Phobos-next" library which could be used here, which includes
    // all those functional methods that ARE @nogc, but I didn't want to use any external libraries just yet.

    T sumOfProductsOfSubsets = 0;
    foreach(subset; numbers.powerSet!(T)) {
        // Since we should ignore 0's completely, we should also ignore them when calculating
        // the length of the subset.

        // Throw away any subset that has at least one 0 in it, its sub-subset without 0s will also
        // be returned anyway.
        bool doesHave0 = false;
        foreach(n; subset) {
            if (n == 0) {
                doesHave0 = true;
                break;
            }
        }

        const subsetLength = subset.length;
        if (subsetLength > 0 && !doesHave0) {
            T subsetLcm = 1;
            if (subsetLength == 1) {
                subsetLcm = subset.front;
            }
            else { // ==> if (subsetLength >= 2)

                // How to find the LCM of multiple inputs?
                // 1) For the simple 2 number case:
                // (n*m)/gcd(n,m)
                // 2) For the general case:
                // For each subset (a,b,c,d...):
                // Calculate the above formula:
                // lcm'(x,y) = x*y/gcd(x,y)
                // lcm(a,b,c,...y, z) = lcm'(a, lcm'(b, lcm'..., lcm'(y, z))))...)
                // (See also: https://www.geeksforgeeks.org/lcm-of-given-array-elements/)
                // 
                // Then calculate:
                // sumOfMultiples(lcm, upperBound - 1)
                // And add/substract it from the general sum.
                foreach(n; subset) {
                    if (n > 0) {
                        subsetLcm = (n * subsetLcm) / gcd(n, subsetLcm);
                    }
                }
            }
            if (subsetLcm < upperBound) {
                // See cases 1-3 above for the full explanation of why we multiply by -1 or 1 here.
                sumOfProductsOfSubsets += sumOfMultiples(subsetLcm, upperBound - 1) *
                    ((subsetLength % 2 == 0) ? -1 : 1);
            }
        }
    }
    return sumOfProductsOfSubsets;
}

// Entry point for testing the 3 algorithms above for the problem.
T calculateSum(T)(T[] numbers, T upperBound) pure
{
    // Run the 3 algorithms and compare their result before forwarding the answer to the 
    // actual unit test.
    auto result1 = calculateSum1(numbers, upperBound);
    auto result2 = calculateSum2(numbers, upperBound);
    auto result3 = calculateSum3(numbers, upperBound);

    assert(result1 == result2 && result2 == result3);
    return result1;
}

unittest
{
    immutable int allTestsEnabled = 1;

    // no multiples within limit
    assert(calculateSum([3, 5], 1) == 0);

    static if (allTestsEnabled)
    {
        // one factor has multiples within limit
        assert(calculateSum([3, 5], 4) == 3);

        // more than one multiple within limit
        assert(calculateSum([3], 7) == 9);

        // more than one factor with multiples within limit
        assert(calculateSum([3, 5], 10) == 23);

        // each multiple is only counted once
        assert(calculateSum([3, 5], 100) == 2318);

        // a much larger limit
        assert(calculateSum([3, 5], 1000) == 233168);

        // three factors
        assert(calculateSum([7, 13, 17], 20) == 51);

        // factors not relatively prime
        assert(calculateSum([4, 6], 15) == 30);

        // some pairs of factors relatively prime and some not
        assert(calculateSum([5, 6, 8], 150) == 4419);

        // one factor is a multiple of another
        assert(calculateSum([5, 25], 51) == 275);

        // much larger factors
        assert(calculateSum([43, 47], 10000) == 2203160);

        // all numbers are multiples of 1
        assert(calculateSum([1], 100) == 4950);

        // no factors means an empty sum
        assert(calculateSum([0], 10000) == 0);

        // the only multiple of 0 is 0
        assert(calculateSum([0], 1) == 0);

        // the factor 0 does not affect the sum of multiples of other factors
        assert(calculateSum([3, 0], 4) == 3);

        // solutions using include-exclude must extend to cardinality greater than 3
        assert(calculateSum([2, 3, 5, 7, 11], 10000) == 39614537);
    }
}
