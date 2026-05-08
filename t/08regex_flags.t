use Test::More tests => 30;
use Regexp::Parser;
ok(1);

my $r = Regexp::Parser->new;

# Test 1: regex with 'x' flag -- whitespace should be ignored
ok( $r->regex(' foo [ ] bar ', 'x') );
is( $r->visual, 'foo[ ]bar', 'x flag strips whitespace' );

# Test 2: regex with 'i' flag -- exact nodes should become exactf
ok( $r->regex('abc', 'i') );
ok( my $w = $r->walker and 1 );
while (my ($n, $d) = $w->()) {
  chomp(my $exp = <DATA>);
  is( join("\t", $d, $n->family, $n->type, $n->visual), $exp );
}
is( scalar(<DATA>), "---\n" );

# Test 3: regex with 'is' flags combined
ok( $r->regex('.', 'is') );
$w = $r->walker;
my ($n) = $w->();
is( $n->type, 'sany', '/s makes . match \\n (sany type)' );

# Test 4: regex with no flags (default behavior unchanged)
ok( $r->regex('abc') );
$w = $r->walker;
($n) = $w->();
is( $n->type, 'exact', 'no flags: exact, not exactf' );

# Test 5: regex with 'x' flag -- comments should be ignored
ok( $r->regex('a # comment', 'x') );
is( $r->visual, 'a', 'x flag strips comments' );

# Test 6: flags do not persist between regex() calls
ok( $r->regex('abc', 'i') );
ok( $r->regex('abc') );
$w = $r->walker;
($n) = $w->();
is( $n->type, 'exact', 'flags do not persist between calls' );

# Test 7: regex with 'm' flag
ok( $r->regex('^a', 'm') );
$w = $r->walker;
($n) = $w->();
is( $n->type, 'mbol', '/m makes ^ match \\n boundaries' );

# Test 8: /xx flag strips spaces and tabs inside character classes (Perl 5.26+)
ok( $r->regex('[a b c]', 'xx') );
is( $r->visual, '[abc]', 'xx flag strips spaces in char class' );

# Test 9: /xx flag does not strip newlines inside character classes
ok( $r->regex("[a\nb]", 'xx') );
is( $r->visual, "[a\nb]", 'xx flag preserves newlines in char class' );

# Test 10: /xx flag strips tabs inside character classes
ok( $r->regex("[a\tb]", 'xx') );
is( $r->visual, '[ab]', 'xx flag strips tabs in char class' );

# Test 11: /x flag does NOT strip spaces inside character classes
ok( $r->regex('[a b]', 'x') );
is( $r->visual, '[a b]', 'x flag preserves spaces in char class' );

# Test 12: inline (?xx:) strips spaces inside character classes
ok( $r->regex('(?xx:[a b c])') );
is( $r->visual, '(?xx:[abc])', 'inline (?xx:) strips spaces in char class' );

# Test 13: /xx escaping -- backslash-space is kept
ok( $r->regex('[a\\ b]', 'xx') );
is( $r->visual, '[a\ b]', 'xx flag preserves escaped space in char class' );

__DATA__
0	exact	exactf	abc
---
