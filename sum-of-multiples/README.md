# Sum Of Multiples

Given a number, find the sum of all the unique multiples of particular numbers up to
but not including that number.

If we list all the natural numbers below 20 that are multiples of 3 or 5,
we get 3, 5, 6, 9, 10, 12, 15, and 18.

The sum of these multiples is 78.

Notes on my solution
====================
After solving this exercise with a naive but inefficient functional approach one-liner, I tried to do better and added a second solution which doesn't run multiple times over the input range, but just once.

Only then I noticed that this was based on a problem from the Project Euler set, and figured out that there must be some nice mathematical shortcut for this.  Turns out I was correct, there's a laughingly simple way to optimize the summation, using basic middle-school algebra.  
So I decided to write a @nogc solution, since if we can use a simple formula for the summation, there's no need for any allocation, right?

Turns out I was correct, but that was far, far more difficult than I thought.  Mostly due to the @nogc constraints I had put upon myself.

Because each combination of factors also contributes to the sum, those multiplicities had to be removed.  So in essence I had to go over all combinations, which was a power set!  
Power set - that was something I had already done  before in the "perfect numbers" problem!

However, in that problem I used a somewhat inefficient solution which I basically copied from the Haskell code on Rosetta code, which involves lots of allocations, and I couldn't use it here when I wanted a @nogc solution.
So I took the other algorithm used on that site (the one also used for the D solution there), which is to enumerate the bits of all numbers 0..2^n , where each combination of bits give a subset of the power-set.  I had planned on making this a functional solution as well, so I first wrote a generator which returns this power set.

When I got to the algorithm for the problem itself, I found out I couldn't use any of the range or algorithm functions since none of them is marked with @nogc (or at least, none of the ones I needed).  I found out there's a library which implements them as @nogc (Phobos-next) but I wanted to avoid using external libraries for my solution.

So this means I had to write it all iteratively.  This wasn't bad, actually, and wasn't the real problem, but made the power-set generator of generators a bit overblown for the solution.  I left it in, though.

My main problems were algorithmcal:
* Figuring out that if the numbers aren't relatively prime (have a common factor > 1), then the number they contribute twice to the sum isn't their product, but their lowest common multiple.  It has been a long time since high-school or college and I didn't even remember how this was called.  I did have an intuition it was related to the GCD somehow so I I found it out at the end.
* After finding out that I should calculate the lowest common multiple (LCM) for each group of numbers, I couldn't figure out how at first, and then I found the simple formula using the GCD for 2 numbers.  
* However I was wrong on how to generalize this formula for LCM for more than 2 numbers.  That took a while to correct.
* Then I ran into problems since I didn't figure out that the subset of 3 or more numbers should add back what all the subsets of 2 numbers decremented from the total sum.  This took a while to figure out. 
* At first I wrote a naive and wrong algorithm which just added the sum of each single number in one loop, then substracted from the sum the products of subsets of the power set in another loop.  After stages 1-4 I had to refactor it, but at the end I had a single, general, big loop that does all the work.
* I still had some problems with sequences containing 0, since I didn't have "filter" available and I had @nogc, I couldn't just dup the array.  I tried several approaches until it finally dawned on me that any such sequence could be completely ignored since its sub-sequence which doesn't contain a zero will be returned anyway as well as another part of the sub-set.

Well, actually, I'm still not convinced my 3rd solution doesn't have a bug somewhere, but I've spent enough time on it so I'm leaving it as it is.

The unit tests were very nice!  Especially for my 3rd solution, they touched upon each failure point with an example that was small enough for me to reproduce and think about a proper solution for the problem.

## Getting Started

Make sure you have read [D page](http://exercism.io/languages/d) on
exercism.io.  This covers the basic information on setting up the development
environment expected by the exercises.

## Passing the Tests

Get the first test compiling, linking and passing by following the [three
rules of test-driven development](http://butunclebob.com/ArticleS.UncleBob.TheThreeRulesOfTdd).
Create just enough structure by declaring namespaces, functions, classes,
etc., to satisfy any compiler errors and get the test to fail.  Then write
just enough code to get the test to pass.  Once you've done that,
uncomment the next test by moving the following line past the next test.

```D
static if (all_tests_enabled)
```

This may result in compile errors as new constructs may be invoked that
you haven't yet declared or defined.  Again, fix the compile errors minimally
to get a failing test, then change the code minimally to pass the test,
refactor your implementation for readability and expressiveness and then
go on to the next test.

Try to use standard D facilities in preference to writing your own
low-level algorithms or facilities by hand.  [DRefLanguage](https://dlang.org/spec/spec.html)
and [DReference](https://dlang.org/phobos/index.html) are references to the D language and D standard library.


## Source

A variation on Problem 1 at Project Euler [http://projecteuler.net/problem=1](http://projecteuler.net/problem=1)

## Submitting Incomplete Solutions
It's possible to submit an incomplete solution so you can see how others have completed the exercise.
