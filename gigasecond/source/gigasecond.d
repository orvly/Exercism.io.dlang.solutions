module gigasecond;

import std.datetime;
import core.time;
DateTime gsAnniversary(DateTime startDate) {
    return startDate + dur!"seconds"(1_000_000_000);
}

unittest {
const int allTestsEnabled = 1;

    assert(gsAnniversary(DateTime(2011, 4, 25)) == DateTime(2043, 1, 1, 1, 46, 40));
static if (allTestsEnabled) {
    assert(gsAnniversary(DateTime(1977, 6, 13)) == DateTime(2009, 2, 19, 1, 46, 40));
    assert(gsAnniversary(DateTime(1959, 7, 19)) == DateTime(1991, 3, 27, 1, 46, 40));
    assert(gsAnniversary(DateTime(2015, 1, 24, 22, 0, 0)) == DateTime(2046, 10, 2, 23, 46, 40));
    assert(gsAnniversary(DateTime(2015, 1, 24, 23, 59, 59)) == DateTime(2046, 10, 3, 1, 46, 39));

    //check that it doesn't mutate the argument
    auto d = DateTime(2011, 4, 25);
    assert(gsAnniversary(d) == DateTime(2043, 1, 1, 1, 46, 40));
    assert(d == DateTime(2011, 4, 25));

    //For fun add a test for your own gigasecond anniversary
}

}
