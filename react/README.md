# Notes on my solution

1. This was a relatively difficult, as I tried to solve it using with only a single pass.  Initially I tried using a cascade of events, but it was impossible to do in a single pass.
 
2. I then thought that the way the Reactor class is used in the unit test is some sort of hint - it's used as if it should be some sort of orchestrator - InputCell and ComputeCell objects are created using the strange syntax for nested classes, so that their constructor would get the enclosing class as a parameter.  So I figured out that the exercise wanted me to use Reactor as an orchestrator, meaning that it should be the one going over the node explicitly (instead of implicitly doing it with events/callbacks)

3. However, this turned out to be something of a mixed signal - the Reactor object in the unit tests **isn't** created as an object (not using *new*) for some reason.  It also can't be defined as a struct because the syntax used in the unit tests for creating objects of the nested classes wouldn't compile.

4. Due to thie mixed signal, I ended up using a static tree data structure "inside" Reactor, which sorts of beats the purpose of using it at all, but I could implement a nice DFS traversal algorithm that only reaches cells it should reach, and goes down only when the value is stable. 

5. But at the end I think doing it with 2 separate event cascades wouldn't have been simpler.  The other D solution on exercism did that and the code is more concise than mine.      
 
-------
# Problem Description
# React

Implement a basic reactive system.

Reactive programming is a programming paradigm that focuses on how values
are computed in terms of each other to allow a change to one value to
automatically propagate to other values, like in a spreadsheet.

Implement a basic reactive system with cells with settable values ("input"
cells) and cells with values computed in terms of other cells ("compute"
cells). Implement updates so that when an input value is changed, values
propagate to reach a new stable system state.

In addition, compute cells should allow for registering change notification
callbacks.  Call a cell’s callbacks when the cell’s value in a new stable
state has changed from the previous stable state.

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


## Submitting Incomplete Solutions
It's possible to submit an incomplete solution so you can see how others have completed the exercise.
