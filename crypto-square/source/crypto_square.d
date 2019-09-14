
module crypto;
import std.stdio: writeln;
import std.math: sqrt, ceil;
import std.algorithm.iteration: filter, map;
import std.ascii: isAlphaNum;
import std.range: appender;
import std.conv: to;
import std.algorithm.comparison: min;
import std.string: strip, toLower;

struct Cipher
{
private:
    string plainText_;
    string normalizedText_;
    string[] plainTextSegments_;
    bool isNormalized_ = false;
public:
    this(string plainText) {
        plainText_ = plainText;
        normalizedText_ = buildNormalizedPlainText();
        plainTextSegments_ = buildPlainTextSegments();
    }
    string normalizePlainText() {
        return normalizedText_;
    }
    uint size() {
        return normalizedText_.length.to!float.sqrt.ceil.to!uint;
    }
    string[] plainTextSegments() {
        return plainTextSegments_;
    }
    Cipher* normalize() {
        isNormalized_ = true;
        return &this;
    }
    string cipherText() {
        auto appender = appender!string;
        appender.reserve(this.normalizedText_.length);
        foreach(j; 0..size()) {
            foreach(segment; plainTextSegments_) {
                if (j < segment.length ) {
                    appender ~= segment[j];
                }
            }
            if (isNormalized_) {
                appender ~= ' ';
            }
        }
        debug(2) writeln(appender.data);
        import std.string;
        return appender.data.strip;
    }

private:
    string buildNormalizedPlainText() {
        auto appender = appender!string;
        appender.reserve(plainText_.length);
        appender ~= plainText_.filter!isAlphaNum.map!toLower;
        return to!string(appender.data);
    }
    string[] buildPlainTextSegments() {
        auto columns = size();
        auto rows = (normalizedText_.length.to!float / columns).ceil.to!uint;
        debug(2) writeln(normalizedText_.length, ' ', rows, ' ', columns); 
        auto appender = appender!(string[]);
        appender.reserve(rows);
        foreach(i; 0..rows) {
            auto limit = min( (i+1) * columns , normalizedText_.length);
            appender ~= normalizedText_[i * columns..limit];
        }
        debug(2) writeln(appender.data);
        return appender.data;
    }
}

unittest
{
immutable int allTestsEnabled = 1;

// normalize_strange_characters
{
	auto theCipher = new Cipher("s#$%^&plunk");
	assert("splunk" == theCipher.normalizePlainText());
}
static if (allTestsEnabled)
{

// normalize_numbers
{
	auto theCipher = new Cipher("1, 2, 3 GO!");
	assert("123go" == theCipher.normalizePlainText());
}

// size_of_small_square
{
	auto theCipher = new Cipher("1234");
	assert(2U == theCipher.size());
}

// size_of_slightly_larger_square
{
	auto theCipher = new Cipher("123456789");
	assert(3U == theCipher.size());
}

// size_of_non_perfect_square
{
	auto theCipher = new Cipher("123456789abc");
	assert(4U == theCipher.size());
}

// size_of_non_perfect_square_less
{
	auto theCipher = new Cipher("zomgzombies");
	assert(4U == theCipher.size());
}

// plain_text_segments_from_phrase
{
	const string[] expected = ["neverv", "exthin", "eheart", "withid", "lewoes"];
	auto theCipher = new Cipher("Never vex thine heart with idle woes");
	const auto actual = theCipher.plainTextSegments();

	assert(expected == actual);
}

// plain_text_segments_from_complex_phrase
{
	const string[] expected = ["zomg", "zomb", "ies"];
	auto theCipher = new Cipher("ZOMG! ZOMBIES!!!");
	const auto actual = theCipher.plainTextSegments();

	assert(expected == actual);
}

// Cipher_text_short_phrase
{
	auto theCipher = new Cipher("Time is an illusion. Lunchtime doubly so.");
	assert("tasneyinicdsmiohooelntuillibsuuml" == theCipher.cipherText());
}

// Cipher_text_long_phrase
{
	auto theCipher = new Cipher("We all know interspecies romance is weird.");
	assert("wneiaweoreneawssciliprerlneoidktcms" == theCipher.cipherText());
}

// normalized_Cipher_text1
{
	auto theCipher = new Cipher("Madness, and then illumination.");
	assert("msemo aanin dnin ndla etlt shui" == theCipher.normalize.cipherText());
}

// normalized_Cipher_text2
{
	auto theCipher = new Cipher("Vampires are people too!");
	assert("vrel aepe mset paoo irpo" == theCipher.normalize.cipherText());
}
}

}
