# Tests for \g{N} backreferences and /a/d/l/u modifier flags (Perl 5.10+/5.14+)

use Test::More tests => 54;
use Regexp::Parser;
ok(1, 'loaded');

my $r = Regexp::Parser->new;

# --- \g{N} absolute backreferences ---

# \g{1} — equivalent to \1
ok( $r->regex('(a)\\g{1}') );
is( $r->visual, '(a)\\g{1}' );

# \g1 — no-braces form
ok( $r->regex('(a)\\g1') );
is( $r->visual, '(a)\\g1' );

# \g{2} — reference to second capture group
ok( $r->regex('(a)(b)\\g{2}') );
is( $r->visual, '(a)(b)\\g{2}' );

# --- \g{-N} relative backreferences ---

# \g{-1} — refer to the most recent capture group
ok( $r->regex('(a)\\g{-1}') );
is( $r->visual, '(a)\\g{-1}' );

# \g{-2} with two groups — refer to first group
ok( $r->regex('(a)(b)\\g{-2}') );
is( $r->visual, '(a)(b)\\g{-2}' );

# --- qr() for backrefs ---

# \g{1} should produce working qr (emits \1 for Perl)
$r->regex('(a)\\g{1}');
ok( "aa" =~ $r->qr );
ok( "ab" !~ $r->qr );

# \g{-1} should produce working qr
$r->regex('(a)\\g{-1}');
ok( "aa" =~ $r->qr );
ok( "ab" !~ $r->qr );

# \g1 should produce working qr
$r->regex('(a)\\g1');
ok( "aa" =~ $r->qr );
ok( "ab" !~ $r->qr );

# --- /a, /d, /l, /u charset flags ---

# (?u:...) — unicode flag
ok( $r->regex('(?u:abc)') );
is( $r->visual, '(?u:abc)' );

# (?a:...) — ASCII flag
ok( $r->regex('(?a:abc)') );
is( $r->visual, '(?a:abc)' );

# (?l:...) — locale flag
ok( $r->regex('(?l:abc)') );
is( $r->visual, '(?l:abc)' );

# (?d:...) — default flag
ok( $r->regex('(?d:abc)') );
is( $r->visual, '(?d:abc)' );

# combined flags: (?ui:...)
ok( $r->regex('(?ui:abc)') );
is( $r->visual, '(?ui:abc)' );

# flag assertion: (?u) inline
ok( $r->regex('(?u)abc') );

# --- error cases ---

# \g{99} — nonexistent group should error on parse
$r->regex('(a)\\g{99}');
eval { $r->visual };
like( $@, qr/nonexistent group/, '\\g{99} errors' );

# \g{-5} — relative ref too far back should error on parse
$r->regex('(a)\\g{-5}');
eval { $r->visual };
like( $@, qr/nonexistent group/, '\\g{-5} errors' );

# \g without number or braces should fail at regex() time
ok( !$r->regex('(a)\\g'), '\\g alone fails' );

# --- \g{+N} forward relative backreferences (Perl 5.10+) ---

# \g{+1} — refer to the next capture group
ok( $r->regex('(a)\\g{+1}(b)'), '\\g{+1} parses' );
is( $r->visual, '(a)\\g{+1}(b)', '\\g{+1} visual' );

# \g{+2} — refer to the group two ahead
ok( $r->regex('(a)\\g{+2}(b)(c)'), '\\g{+2} parses' );
is( $r->visual, '(a)\\g{+2}(b)(c)', '\\g{+2} visual' );

# \g{+1} with named groups
ok( $r->regex('(?<x>a)\\g{+1}(?<y>b)'), '\\g{+1} with named groups parses' );
is( $r->visual, '(?<x>a)\\g{+1}(?<y>b)', '\\g{+1} with named groups visual' );

# \g{+1} tree node resolves to absolute group number
ok( $r->regex('(a)\\g{+1}(b)'), '\\g{+1} parse for tree inspection' );
{
  my $w = $r->walker;
  my @walk;
  while (my $node = $w->()) { push @walk, $node; }
  my @refs = grep { $_->isa('Regexp::Parser::ref') } @walk;
  is( scalar @refs, 1, '\\g{+1} produces one ref node' );
  is( $refs[0]->nparen, 2, '\\g{+1} resolves to absolute group 2' );
}

# \g{+N} error for out-of-range
$r->regex('(a)\\g{+5}');
eval { $r->visual };
like( $@, qr/nonexistent group/, '\\g{+5} with only 1 group errors' );

# --- \k{name} brace-delimited named backreference (Perl 5.32+) ---

# \k{name} parses
ok( $r->regex('(?<foo>bar)\\k{foo}'), '\\k{name} parses' );
is( $r->visual, '(?<foo>bar)\\k{foo}', '\\k{name} visual' );

# \k{name} qr matching
$r->regex('(?<foo>.)\\k{foo}');
ok( "aa" =~ $r->qr, '\\k{name} qr matches' );
ok( "ab" !~ $r->qr, '\\k{name} qr rejects mismatch' );

# \k{name} tree node
ok( $r->regex('(?<foo>bar)\\k{foo}'), '\\k{name} parse for tree inspection' );
{
  my $w = $r->walker;
  my @walk2;
  while (my $node = $w->()) { push @walk2, $node; }
  my @nrefs = grep { $_->isa('Regexp::Parser::named_ref') } @walk2;
  is( scalar @nrefs, 1, '\\k{name} produces one named_ref node' );
  is( $nrefs[0]->name, 'foo', '\\k{name} has correct name' );
}

# all three \k syntaxes produce the same node type
for my $pair (
  [ '\\k<bar>',  '(?<bar>x)\\k<bar>' ],
  [ "\\k'bar'",  "(?<bar>x)\\k'bar'" ],
  [ '\\k{bar}',  '(?<bar>x)\\k{bar}' ],
) {
  my ($label, $pat) = @$pair;
  ok( $r->regex($pat), "$label parses" );
  my $w = $r->walker;
  my @w;
  while (my $node = $w->()) { push @w, $node; }
  my @nr = grep { $_->isa('Regexp::Parser::named_ref') } @w;
  is( scalar @nr, 1, "$label produces named_ref" );
}
