module matching_brackets;

bool isParen(char c) @nogc pure {
    return c == '(' || c == ')' || c == '[' || c == ']' || c == '{' || c == '}';
}
bool isOpening(char c) @nogc pure {
    return c == '(' || c == '[' || c == '{';
}
bool isClosingOf(char c, char prev) @nogc pure {
    return c == ')' && prev == '(' || c == ']' && prev == '[' || c == '}' && prev == '{';
}

bool isPaired(string s) @nogc pure {
    import std.typecons;

    enum empty = 0;

    // This implements a @nogc parser, by using the runtime stack instead of the simpler solution
    // of using a dynamically allocated stack.
    Tuple!(bool, string) check(char top, string s) @nogc pure {
        // If we've reached the end of the string, then we're ok (flag in tuple[0]) only if 
        // the top of the stack is empty.
        if (s.length == 0)
            return tuple(top == empty, s);
        const c = s[0];
        const rest = s[1..$];
        // If this isn't a parens character, then we don't care about it,
        // keep recursing into the rest of the string with the last "top" we know about.
        if (!c.isParen)
            return check(top, rest);
        if (c.isOpening && (top.isOpening || top == empty)) {
            // If current char is some opening parens and the last parens were also opening,
            // recurse in order to find the matching parens. See the last "return" line in this function.
            auto match = check(c, rest);
            if (match[0])
                // If we found the matching parens, recurse again, but now start from the position of the
                // matching parens + 1.  This is the position returned by the "rest" parameter in the 
                // last "return" line in this function.
                return check(top, match[1]);
            else
                // If we didn't find a matching parens, return the error.
                return tuple(false, s);
        }
        // If we got here, the new char must be a closing parens.  We succeed if it matches the one at 
        // the top of the stack.  We also return "rest" which is used to continue recursing into the
        // string from this point forward at the return site.
        return tuple(c.isClosingOf(top), rest);
    }
    return check(empty, s)[0];
}

unittest
{
    immutable int allTestsEnabled = 1;

    // paired square brackets
    assert(isPaired("[]"));

    static if (allTestsEnabled)
    {
        // empty string
        assert(isPaired(""));

        // unpaired brackets
        assert(!isPaired("[["));

        // wrong ordered brackets
        assert(!isPaired("}{"));

        // wrong closing bracket
        assert(!isPaired("{]"));

        // paired with whitespace
        assert(isPaired("{ }"));

        // partially paired brackets
        assert(!isPaired("{[])"));

        // simple nested brackets
        assert(isPaired("{[]}"));

        // several paired brackets
        assert(isPaired("{}[]"));

        // paired and nested brackets
        assert(isPaired("([{}({}[])])"));

        // unopened closing brackets
        assert(!isPaired("{[)][]}"));

        // unpaired and nested brackets
        assert(!isPaired("([{])"));

        // paired and wrong nested brackets
        assert(!isPaired("[({]})"));

        // paired and incomplete brackets
        assert(!isPaired("{}["));

        // too many closing brackets
        assert(!isPaired("[]]"));

        // math expression
        assert(isPaired("(((185 + 223.85) * 15) - 543)/2"));

        // complex latex expression
        assert(isPaired(
                "\\left(\\begin{array}{cc} \\frac{1}{3} & x\\\\ \\mathrm{e}^{x} &... x^2 \\end{array}\\right)"));
    }
}
