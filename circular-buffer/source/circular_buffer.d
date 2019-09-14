
module circular;
import std.stdio;

class Buffer(T)
{
private:
    T[] _buf;
    size_t _begin = 0;
    size_t _end = 0;
    bool _isEmpty = true;

    auto isFull() {
        return !_isEmpty && _begin == _end;
    }

public:
    this(size_t size) {
        _buf = new T[size];
    }
   
    T pop() {
        import std.exception;
        enforce(!_isEmpty, "Buffer is empty");
        auto val = _buf[_begin];
        _begin = (_begin + 1) % _buf.length;
        _isEmpty = _end == _begin;
        return val;
    }

    void push(const(T) val) {
        import std.exception;
        enforce(!isFull, "Buffer is full");
        _buf[_end] = val;
        _end = (_end + 1) % _buf.length;
        _isEmpty = false;
    }

    void forcePush(const(T) val) {
        _buf[_end] = val;
        auto wasFull = isFull;
        _end = (_end + 1) % _buf.length;
        if (wasFull) {
            _begin = (_begin + 1) % _buf.length;
        }
        _isEmpty = false;
    }

    void clear() {
        _isEmpty = true;
        _end = _begin;
    }
}

unittest
{
import std.exception : assertThrown;

immutable int allTestsEnabled = 1;

// test read empty buffer
{
	auto myBuffer = new Buffer!(int)(1UL);
	assertThrown(myBuffer.pop(), "Empty buffer should throw exception if popped!");
}

static if (allTestsEnabled)
{

// test write and read back one item
{
	auto myBuffer = new Buffer!(char)(1);
	myBuffer.push('1');
	assert(myBuffer.pop() == '1');
}

// test write and read back multiple items
{
	auto myBuffer =  new Buffer!(char)(2);
	myBuffer.push('1');
	myBuffer.push('2');
	assert(myBuffer.pop() == '1');
	assert(myBuffer.pop() == '2');
}

// test clearing the buffer
{
	auto myBuffer = new Buffer!(char)(3);
	myBuffer.push('1');
	myBuffer.push('2');
	myBuffer.push('3');

	myBuffer.clear();
	assertThrown(myBuffer.pop(), "Empty buffer should throw exception if popped!");
}

// test alternate write and read
{
	auto myBuffer = new Buffer!(char)(2);
	myBuffer.push('1');
	assert(myBuffer.pop() == '1');
	myBuffer.push('2');
	assert(myBuffer.pop() == '2');
}

// test read back oldest item
{
	auto myBuffer = new Buffer!(char)(4);
	myBuffer.push('1');
	myBuffer.push('2');
	myBuffer.pop();
	myBuffer.push('3');
	myBuffer.pop();

	assert(myBuffer.pop() == '3');
}

// test write buffer
{
	auto myBuffer = new Buffer!(char)(3);
	myBuffer.push('1');
	myBuffer.push('2');
	myBuffer.push('3');

	assertThrown(myBuffer.push('4'), "Full buffer should throw exception if new element pushed!");
}

// test forcePush full buffer
{
	auto myBuffer = new Buffer!(char)(3);
	myBuffer.push('1');
	myBuffer.push('2');
	myBuffer.push('3');

	myBuffer.forcePush('A');
	assert(myBuffer.pop() == '2');
	assert(myBuffer.pop() == '3');
	assert(myBuffer.pop() == 'A');
}

// test forcePush non-full buffer
{
	auto myBuffer = new Buffer!(int)(2);
	myBuffer.forcePush(1000);
	myBuffer.forcePush(2000);

	assert(myBuffer.pop() == 1000);
	assert(myBuffer.pop() == 2000);
}

// test alternate read and forcePush
{
	auto myBuffer = new Buffer!(char)(5);
	myBuffer.push('1');
	myBuffer.push('2');
	myBuffer.push('3');
	myBuffer.pop();
	myBuffer.pop();

	myBuffer.push('4');
	myBuffer.pop();

	myBuffer.push('5');
	myBuffer.push('6');
	myBuffer.push('7');
	myBuffer.push('8');
	myBuffer.forcePush('A');
	myBuffer.forcePush('B');

	assert(myBuffer.pop() == '6');
	assert(myBuffer.pop() == '7');
	assert(myBuffer.pop() == '8');
	assert(myBuffer.pop() == 'A');
	assert(myBuffer.pop() == 'B');
	assertThrown(myBuffer.pop(), "Empty buffer should throw exception if popped!");
}

}

}
