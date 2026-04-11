use strict;
use warnings;
use Test::More;
use Regexp::Parser;

my $r = Regexp::Parser->new;

# === (?'name'...) single-quote named capture ===

ok( $r->regex("(?'word'\\w+)"), "(?'name'...) parses" );
is( $r->visual, "(?'word'\\w+)", "(?'name'...) visual preserves single quotes" );

# Tree structure
{
  $r->regex("(?'foo'bar)");
  $r->parse;
  my @nodes = @{ $r->root };
  is( $nodes[0]->family, 'open', "(?'foo'...) family is open" );
  is( $nodes[0]->nparen, 1, "(?'foo'...) is capture 1" );
  is( $nodes[0]->name, 'foo', "(?'foo'...) name is foo" );
  is( $nodes[0]->raw, "(?'foo'", "(?'foo'...) raw uses single quotes" );
}

# Captures array
{
  $r->regex("(?'x'a)(?'y'b)");
  $r->parse;
  my @cap = @{ $r->captures };
  is( scalar @cap, 2, "two captures" );
  is( $cap[0]->name, 'x', "first capture name" );
  is( $cap[1]->name, 'y', "second capture name" );
}

# Round-trip: parse -> visual -> re-parse -> visual
{
  my $rx = "(?'name'\\d+)";
  $r->regex($rx);
  my $v1 = $r->visual;
  ok( $r->regex($v1), "round-trip re-parse" );
  is( $r->visual, $v1, "round-trip visual stable" );
}

# Mixed with (?<name>...) angle-bracket syntax
{
  ok( $r->regex("(?<a>x)(?'b'y)"), "mixed angle + single-quote" );
  $r->parse;
  my @cap = @{ $r->captures };
  is( $cap[0]->raw, "(?<a>", "angle bracket raw" );
  is( $cap[1]->raw, "(?'b'", "single quote raw" );
}

# Named backref to single-quote captured group
{
  ok( $r->regex("(?'q'[\"']).*?\\k<q>"), "named backref to single-quote group" );
  is( $r->visual, "(?'q'[\"']).*?\\k<q>", "backref visual" );
}

# qr() output
{
  $r->regex("(?'name'\\w+)");
  $r->parse;
  my $qr = $r->qr;
  like( $qr, qr/\(\?'name'/, "qr() preserves single-quote syntax" );
}

# === bare \g-N (negative relative backref without braces) ===

ok( $r->regex("(a)\\g-1"), "\\g-1 bare parses" );
is( $r->visual, "(a)\\g-1", "\\g-1 bare visual" );

ok( $r->regex("(a)(b)\\g-2"), "\\g-2 bare parses" );
is( $r->visual, "(a)(b)\\g-2", "\\g-2 bare visual" );

# Tree structure for bare \g-N
{
  $r->regex("(x)(y)\\g-1");
  $r->parse;
  my @nodes = @{ $r->root };
  # nodes: open(1), open(2), ref
  my $ref = $nodes[2];
  is( $ref->family, 'ref', "\\g-1 family is ref" );
  # \g-1 from 2 groups = group 2
  is( $ref->visual, "\\g-1", "\\g-1 visual" );
}

# Braced forms still work
ok( $r->regex("(a)\\g{-1}"), "\\g{-1} braced still works" );
ok( $r->regex("(a)\\g{1}"), "\\g{1} braced still works" );
ok( $r->regex("(a)\\g1"), "\\g1 bare still works" );

# Invalid bare \g-N (reference before group 1)
# Error fires on tree-building pass, so must call visual/parse
{
  $r->regex("(a)\\g-2");
  my $vis = eval { $r->visual };
  ok( $@, "\\g-2 with 1 group errors on parse" );
}

done_testing;
