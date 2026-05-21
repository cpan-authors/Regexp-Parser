use Test::More tests => 31;
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

# Test 8: g/c/o flags on fresh parser don't crash
{
  my $fresh = Regexp::Parser->new;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  ok( $fresh->regex('abc', 'g'), 'g flag on fresh parser does not crash' );
  is( $fresh->visual, 'abc', 'g flag: regex parses correctly' );
  is( scalar @warns, 1, 'g flag: one warning emitted' );
  like( $warns[0], qr/Useless.*\bg\b/, 'g flag: warning mentions g' );
}

{
  my $fresh = Regexp::Parser->new;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  ok( $fresh->regex('abc', 'c'), 'c flag on fresh parser does not crash' );
  is( scalar @warns, 1, 'c flag: one warning emitted' );
}

{
  my $fresh = Regexp::Parser->new;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  ok( $fresh->regex('abc', 'o'), 'o flag on fresh parser does not crash' );
  is( scalar @warns, 1, 'o flag: one warning emitted' );
}

# Test 9: mixed valid + useless flags
{
  my $fresh = Regexp::Parser->new;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  ok( $fresh->regex('abc', 'ig'), 'ig flags: no crash' );
  my $w = $fresh->walker;
  my ($n) = $w->();
  is( $n->type, 'exactf', 'ig flags: /i applied (exactf)' );
  is( scalar @warns, 1, 'ig flags: one warning for g only' );
}

# Test 10: xx flag via API sets double-x bit
{
  my $fresh = Regexp::Parser->new;
  ok( $fresh->regex('a b', 'xx'), 'xx flag via API' );
  is( $fresh->visual, 'ab', 'xx flag: whitespace stripped' );
}

__DATA__
0	exact	exactf	abc
---
