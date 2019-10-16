module react;

class Reactor(T) {
    import std.algorithm;

    static class TreeNode {
        Cell cell;
        TreeNode[] nodes;
        TreeNode[] parents;
        bool updated;
        this(Cell c) { cell = c; }
    }
    static TreeNode[Cell] _cellToNode;

    static void addInputNode(InputCell c) {
        auto node = new TreeNode(c);
        _cellToNode[c] = node;
    }

    static void addComputeNode(ComputeCell c, Cell p1, Cell p2) {
        auto node = new TreeNode(c);
        _cellToNode[c] = node;

        void connect(Cell c) {
            auto parentNode = _cellToNode[c];
            parentNode.nodes ~= node;
            node.parents ~= parentNode;
        }
        connect(p1);
        if (p2 !is null) {
            connect(p2);
        }
    }

    // NOTE: This isn't really a "visitor" as in the Visitor pattern, since I don't really have different
    // "visit" implementations, I have 2 different functions, calcValue and raisedChange instead.
    alias Visitor = bool function(TreeNode n);
    static void visitDfs(TreeNode node, Visitor v) {
        if (v(node)) {
            node.nodes.each!(n => visitDfs(n, v));
        }
    }

    // Called whenever an input cell is set.
    // Will propagate the value change throughout the tree.
    // When reaching a node with 2 parents, won't update it unless all parents are updated,
    // and won't go on down propagating the value.
    static void setInput(InputCell inputCell, T value) {
        // Set all cells to updated = true, except... 
        _cellToNode.each!(n => n.updated = true);
        // ... Except for restting those that are in the path below our root (inputCell).
        // The DFS traversal below updates those we reach again in order to continue.
        auto rootNode = _cellToNode[inputCell];
        visitDfs(rootNode, (n) { n.updated = false; return true; });

        inputCell._value = value;
        rootNode.updated = true;

        visitDfs(rootNode, (n) {
            if (n.parents.length == 0) {
                return true;
            }
            // 1) If this node has a single parent, then it's always updated, just calculate
            // the value and go on down in the traversal (==> return true)
            // 2) If this node has two parents, then we will reach it twice. We will know it's the
            // second time if both parents are updated.  Only in the second time are both parents updated,
            // and only then we should continue with the DFS, since only then the value of the node
            // is valid.
            // Before continuing with the DFS, calculate the value, and continue with it only
            // if the value is different than the last time (known by the return value of calcValue)
            if (n.parents.all!(parent => parent.updated) && n.cell.calcValue()) {
                n.updated = true;
                n.cell.raiseChanged;
                return true;
            }
            // If not all parents are updated, don't go on with the DFS traversal. We'll return
            // to this node again later.
            // See (2) above.
            return false;
        });
    }

    alias Expr1 = T function(T);
    alias Expr2 = T function(T, T);
    alias ValueChanged = void delegate(T);
    alias CancelCallback = void delegate();

    abstract class Cell {
        string name;

        private T _value;

        T value() { return _value; }

        // NOTE: The following two aren't really necessary here and it's bad design IMO to having to write it here,
        // since it's only meaningful for the ComputeCell, since I don't use any callbacks in InputCell,
        // nor does InputCell do any calculations.
        // A better thing would have been to write the "full" visitor pattern.  However then the "visit" 
        // part would have looked a no-op as well.
        protected abstract bool calcValue();
        protected abstract void raiseChanged();

    }

    class InputCell : Cell {
        // This is needed to bring the parent value() getter to this class
        // since D doesn't bring overloads from the parent automatically.
        alias value = Cell.value;

        // NOTE: I used "name" for debugging when writing my own unit tests.
        this(T initial, string name = null) {
            this.name = name;
            _value = initial;
            // NOTE: As opposed to C++, it looks like "this" is of the current class type
            // inside the constructor, not of the parent type.  So it's the same as in C# and Java.
            addInputNode(this);
        }
        void value(T newVal) { 
            setInput(this, newVal);
        }
        // NOTE: The following two aren't really necessary here and it's bad design IMO to having to write it here,
        // since it's only meaningful for the ComputeCell, not for the InputCell which doesn't do
        // any calculation or raise any events.
        // A better thing would have been to write the "full" visitor pattern.  However then the "visit" 
        // part would have looked a no-op as well.
        protected override bool calcValue() { return true; }
        protected override void raiseChanged() { }
    }

    class ComputeCell : Cell {
        private T delegate() _eval;
        private ValueChanged[] _changedCallbacks;

        alias value = Cell.value;

        protected override bool calcValue() {
            T prev = _value;
            // Call the lambda we captured in the constructor, it has already captured
            // the parent cells inside it.
            _value = _eval();
            return prev != _value;
        }
        protected override void raiseChanged() {
            _changedCallbacks.each!(f => f(_value));
        }

        // NOTE: I used "name" for debugging
        this(Cell c, Expr1 eval, string name = null) {
            this.name = name;
            // Capture the parent cell value here using a lambda, and keep the capture
            // in our _eval member. This means we don't have to keep 2 separate lambdas for
            // the 1 parameter and 2 parameter cases.
            _eval = () => eval(c.value);
            addComputeNode(this, c, null);
            calcValue();
        }

        // NOTE: I used "name" for debugging
        this(Cell c1, Cell c2, Expr2 eval, string name = null) {
            this.name = name;
            // Capture the parent cell value here using a lambda, and keep the capture
            // in our _eval member. This means we don't have to keep 2 separate lambdas for
            // the 1 parameter and 2 parameter cases.
            _eval = () => eval(c1.value, c2.value);
            addComputeNode(this, c1, c2);
            calcValue();
        }

        CancelCallback addCallback(ValueChanged callback) { 
            _changedCallbacks ~= callback;
            return { _changedCallbacks = _changedCallbacks.remove!(c => c == callback); };
        }
    }
}

unittest {
const int allTestsEnabled = 1;
   {
    // input cells have a value
    Reactor!(int) r;
    auto input = r.new InputCell(10);

    assert(input.value == 10);
  }
static if (allTestsEnabled) {
  {
    // an input cell's value can be set
    Reactor!(int) r;
    auto input = r.new InputCell(4);

    input.value = 20;
    assert(input.value == 20);
  }
  {
    // compute cells calculate initial value
    Reactor!(int) r;
    auto input = r.new InputCell(1);
    auto output = r.new ComputeCell(input, (int x) => x + 1);

    assert(output.value == 2);
  }
  {
    // compute cells take inputs in the right order
    Reactor!(int) r;
    auto one = r.new InputCell(1);
    auto two = r.new InputCell(2);
    auto output = r.new ComputeCell(one, two, (int x, int y) => x + y * 10);

    assert(output.value == 21);
  }
  {
    // compute cells update value when dependencies are changed
    Reactor!(int) r;
    auto input = r.new InputCell(1);
    auto output = r.new ComputeCell(input, (int x) => x + 1);

    input.value = 3;
    assert(output.value == 4);
  }
  {
    // compute cells can depend on other compute cells
    Reactor!(int) r;
    auto input = r.new InputCell(1);
    auto timesTwo = r.new ComputeCell(input, (int x) => x * 2);
    auto timesThirty = r.new ComputeCell(input, (int x) => x * 30);
    auto output = r.new ComputeCell(timesTwo, timesThirty, (int x, int y) => x + y);

    assert(output.value == 32);
    input.value = 3;
    assert(output.value == 96);
  }
    {
    // compute cells fire callbacks
    Reactor!(int) r;
    auto input = r.new InputCell(1);
    auto output = r.new ComputeCell(input, (int x) => x + 1);
    int[] vals;

    output.addCallback((int x) { vals ~= [x]; return; });

    input.value = 3;
    assert(vals.length == 1);
    assert(vals[0] == 4);
  }
  {
    // compute cells only fire on change
    Reactor!(int) r;
    auto input = r.new InputCell(1);
    auto output = r.new ComputeCell(input, (int x) => x < 3 ? 111 : 222);
    int[] vals;

    output.addCallback((int x) { vals ~= [x]; return; });

    input.value = 2;
    assert(vals.length == 0);
    input.value = 3;
    assert(vals.length == 1);
    assert(vals[0] == 222);
  }
  {
    // callbacks can be added and removed
    Reactor!(int) r;
    auto input = r.new InputCell(11);
    auto output = r.new ComputeCell(input, (int x) => x + 1);
    int[] vals1;
    int[] vals2;
    int[] vals3;

    void delegate() cancel1 = output.addCallback((int x) { vals1 ~= [x]; return; });
    output.addCallback((int x) { vals2 ~= [x]; return; });

    input.value = 31;

    cancel1();
    output.addCallback((int x) { vals3 ~= [x]; return; });

    input.value = 41;

    assert(vals1.length == 1);
    assert(vals1[0] == 32);
    assert(vals2.length == 2);
    assert(vals2[0] == 32);
    assert(vals2[1] == 42);
    assert(vals3.length == 1);
    assert(vals3[0] == 42);
  }
  {
    // removing a callback multiple times doesn't interfere with other callbacks
    Reactor!(int) r;
    auto input = r.new InputCell(1);
    auto output = r.new ComputeCell(input, (int x) => x + 1);
    int[] vals1;
    int[] vals2;

    void delegate() cancel1 = output.addCallback((int x) { vals1 ~= [x]; return; });
    output.addCallback((int x) { vals2 ~= [x]; return; });

    foreach (i; 0 .. 10) {
      cancel1();
    }

    input.value = 2;

    assert(vals1.length == 0);
    assert(vals2.length == 1);
    assert(vals2[0] == 3);
  }
  {
    // callbacks should only be called once even if multiple dependencies change
    Reactor!(int) r;
    auto input = r.new InputCell(1);
    auto plusOne = r.new ComputeCell(input, (int x) => x + 1);
    auto minusOne1 = r.new ComputeCell(input, (int x) => x - 1);
    auto minusOne2 = r.new ComputeCell(minusOne1, (int x) => x - 1);
    auto output = r.new ComputeCell(plusOne, minusOne2, (int x, int y) => x * y);
    int[] vals;

    output.addCallback((int x) { vals ~= [x]; return; });

    input.value = 4;

    assert(vals.length == 1);
    assert(vals[0] == 10);
  }
  {
    // callbacks should not be called if dependencies change but output value doesn't change
    Reactor!(int) r;
    auto input = r.new InputCell(1);
    auto plusOne = r.new ComputeCell(input, (int x) => x + 1);
    auto minusOne = r.new ComputeCell(input, (int x) => x - 1);
    auto alwaysTwo = r.new ComputeCell(plusOne, minusOne, (int x, int y) => x - y);
    int[] vals;

    alwaysTwo.addCallback((int x) { vals ~= [x]; return; });

    foreach (i; 0 .. 10) {
      input.value = i;
    }

    assert(vals.length == 0);
  }
  {
    // This is a digital logic circuit called an adder:
    // https://en.wikipedia.org/wiki/Adder_(electronics)
    Reactor!(bool) r;
    auto a = r.new InputCell(false);
    auto b = r.new InputCell(false);
    auto carryIn = r.new InputCell(false);

    auto aXorB = r.new ComputeCell(a, b, (bool x, bool y) => x != y);
    auto sum = r.new ComputeCell(aXorB, carryIn, (bool x, bool y) => x != y);

    auto aXorBAndCin = r.new ComputeCell(aXorB, carryIn, (bool x, bool y) => x && y);
    auto aAndB = r.new ComputeCell(a, b, (bool x, bool y) => x && y);
    auto carryOut = r.new ComputeCell(aXorBAndCin, aAndB, (bool x, bool y) => x || y);

    bool[5][] tests = [
      //            inputs,     expected
      //   a,     b,   cin,  cout,   sum
      [false, false, false, false, false],
      [false, false,  true, false,  true],
      [false,  true, false, false,  true],
      [false,  true,  true,  true, false],
      [ true, false, false, false,  true],
      [ true, false,  true,  true, false],
      [ true,  true, false,  true, false],
      [ true,  true,  true,  true,  true],
    ];

    foreach (test; tests) {
      a.value = test[0];
      b.value = test[1];
      carryIn.value = test[2];

      assert(carryOut.value == test[3]);
      assert(sum.value == test[4]);
    }
  }
}

}
