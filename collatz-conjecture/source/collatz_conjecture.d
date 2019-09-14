module collatz_conjecture;
import std.stdio;

// A naive implementation of the algorithm in D
int steps(long num) {
    import std.exception: enforce;

    enforce(num > 0, "number must be greater than 0");
    int step = 0;
    while(num > 1) {
        ++step;
        num = (num % 2) ? (3 * num + 1) : (num / 2);
    }
    return step;
}


int stepsAsm(long num) {
    import std.exception: enforce;

    enforce(num > 0, "number must be greater than 0");
    return stepsAsmImpl(cast(ulong)num);
}

// Just for fun, I wrote an implementation of the algorithm using inline assembly,
// and also compared speed against the DMD optimizer (my implementation naturally won).
// The algorithm here is based on the optimzied binary one described in the Wikipedia article
// on the Collatz conjecture, here:
// https://en.wikipedia.org/wiki/Collatz_conjecture#As_an_abstract_machine_that_computes_in_base_two
// with some few minor tweaks.
int stepsAsmImpl(ulong num) {
    asm {
        mov RAX, 0; // RAX is the counter, is also the return value.
        push R8;
        push R9;
        push RCX;

        mov R8, num; // R8 is our copy of num
        // If it's 1, exit immediately.
        cmp R8, 1;
        je end;

        // If this is an even number, jump to the shr section below
        bt R8, 0; // Sets CF if bit 0 is 1 => if odd
        jnc handleEven;

    handleOdd:
        // Handle an odd number
        mov R9, R8; // Copy to R9 before modifications
        shl R8, 1;
        inc R8;
        add R8, R9; // At this point, R8 = 2n + 1 + n = 3n+1
        inc RAX; // Increase step counter
        
    handleEven:
        // NOTE: The number MIGHT not be even, so this will put 0 in RCX, which is fine,
        // we don't check it before since it involves an extra branch.

        // Find number of trailing zeros.
        bsf RCX, R8;
        // Shift by this number
        shr R8, CL;
        // Increase step counter by the number of zeros found, since each shift right
        // is considered a single step of the calculation.
        add RAX, RCX; 
        // Now R8 should always be odd, we don't have to check for this again, 
        // we can loop back to handleOdd, unless we've reached one.
        cmp R8, 1;
        jnz handleOdd;

    end:
        pop RCX;
        pop R9;
        pop R8;
    }
}

unittest
{
    import std.exception : assertThrown;
    import std.datetime.stopwatch : StopWatch, AutoStart;

    const int allTestsEnabled = 1;

    debug(2) auto s = stdin.readln();

    // NOTE: Unit tests have been duplicated to also exercise the asm version.

    // zero steps for one
    assert(steps(1) == 0);
    assert(stepsAsm(1) == 0);

    static if (allTestsEnabled)
    {
        // divide if even
        assert(steps(16) == 4);
        assert(stepsAsm(16) == 4);

        // even and odd steps
        assert(steps(12) == 9);
        assert(stepsAsm(12) == 9);

        // large number of even and odd steps
        auto sw = StopWatch(AutoStart.yes);
        assert(steps(1000000) == 152);
        sw.stop();
        long msecs = sw.peek.total!"nsecs";
        writefln("d code: %s nsec", msecs);

        sw.reset();
        sw.start();
        assert(stepsAsm(1000000) == 152);
        sw.stop();
        msecs = sw.peek.total!"nsecs";
        writefln("asm code: %s nsec", msecs);

        // zero is an error
        assertThrown(steps(0));

        // negative value is an error
        assertThrown(steps(-15));
    }
}
