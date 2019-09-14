module armstrong_numbers;

bool isArmstrongNumber(const uint n) {
    import std.math: log10, ceil, pow;
    import std.range: generate, take;
    import std.algorithm.iteration: sum;
    import std.conv: to;

    if (n == 0)
        return true;
    const numDigits = log10(n).ceil.to!uint;
    uint m = n;
    const digitSum = generate!( 
        () { const t = m; m /= 10; return (t % 10).pow(numDigits); } )
        .take(numDigits)
        .sum();
    return digitSum == n;
}

unittest
{
    immutable int allTestsEnabled = 1;

    // Zero is an Armstrong number
    assert(isArmstrongNumber(0));

    static if (allTestsEnabled)
    {
        // Single digit numbers are Armstrong numbers
        assert(isArmstrongNumber(5));

        // There are no 2 digit Armstrong numbers
        assert(!isArmstrongNumber(10));

        // Three digit number that is an Armstrong number
        assert(isArmstrongNumber(153));

        // Three digit number that is not an Armstrong number
        assert(!isArmstrongNumber(100));

        // Four digit number that is an Armstrong number
        assert(isArmstrongNumber(9474));

        // Four digit number that is not an Armstrong number
        assert(!isArmstrongNumber(9475));

        // Seven digit number that is an Armstrong number
        assert(isArmstrongNumber(9926315));

        // Seven digit number that is not an Armstrong number
        assert(!isArmstrongNumber(9926314));
    }
}
