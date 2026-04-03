use strict;
use warnings;

use Test::More tests => 101;
use Regexp::Parser;

my $r = Regexp::Parser->new;

#
# (?(R)...) — bare recursion condition
#

my @bare_rx = (
  q{(?(R)a|b)},
  q{(a(?(R)a|(?1))a)},
);

for my $rx (@bare_rx) {
  ok( $r->regex($rx), "parse $rx" );
  ok( my $w = $r->walker, "walker for $rx" );
  while (my ($n, $d) = $w->()) {
    chomp(my $exp = <DATA>);
    my $got = join("\t", $d, $n->family, $n->type);
    my $vis = $n->visual;
    $got .= "\t$vis" if length $vis;
    is( $got, $exp, "node: $exp" );
  }
  is( scalar(<DATA>), "DONE\n", "walker done for $rx" );
}

#
# (?(R1)...) — numbered recursion condition
#

my @numbered_rx = (
  q{(a)(?(R1)x|y)},
  q{(a)(b)(?(R2)x|y)},
);

for my $rx (@numbered_rx) {
  ok( $r->regex($rx), "parse $rx" );
  ok( my $w = $r->walker, "walker for $rx" );
  while (my ($n, $d) = $w->()) {
    chomp(my $exp = <DATA>);
    my $got = join("\t", $d, $n->family, $n->type);
    my $vis = $n->visual;
    $got .= "\t$vis" if length $vis;
    is( $got, $exp, "node: $exp" );
  }
  is( scalar(<DATA>), "DONE\n", "walker done for $rx" );
}

#
# (?(R&name)...) — named recursion condition
#

my @named_rx = (
  q{(?<foo>a)(?(R&foo)x|b)},
);

for my $rx (@named_rx) {
  ok( $r->regex($rx), "parse $rx" );
  ok( my $w = $r->walker, "walker for $rx" );
  while (my ($n, $d) = $w->()) {
    chomp(my $exp = <DATA>);
    my $got = join("\t", $d, $n->family, $n->type);
    my $vis = $n->visual;
    $got .= "\t$vis" if length $vis;
    is( $got, $exp, "node: $exp" );
  }
  is( scalar(<DATA>), "DONE\n", "walker done for $rx" );
}

#
# Round-trip: parse -> visual -> re-parse -> visual
#

my @roundtrip_rx = (
  q{(?(R)a|b)},
  q{(?(R1)a|b)},
  q{(?(R&name)a|b)},
  q{(a(?(R)a|(?1))a)},
  q{(?<foo>a)(?(R&foo)x|b)},
  q{(a)(?(R12)x|y)},
  q{(?(R)x)},
);

for my $rx (@roundtrip_rx) {
  ok( $r->regex($rx), "roundtrip parse $rx" );
  my $v1 = $r->visual;
  ok( $r->regex($v1), "roundtrip re-parse $v1" );
  my $v2 = $r->visual;
  is( $v2, $v1, "roundtrip stable for $rx" );
}

#
# Node accessors
#

{
  ok( $r->regex(q{(?(R)a|b)}), "parse for groupr accessor" );
  $r->parse;
  my $w = $r->walker;
  $w->(); # ifthen
  my ($cond) = $w->();
  is( $cond->family, 'groupp', 'groupr family is groupp' );
  is( $cond->type, 'groupr', 'groupr type' );
  is( $cond->visual, '(R)', 'groupr visual' );
}

{
  ok( $r->regex(q{(?(R3)a|b)}), "parse for grouprn accessor" );
  $r->parse;
  my $w = $r->walker;
  $w->(); # ifthen
  my ($cond) = $w->();
  is( $cond->family, 'groupp', 'grouprn family is groupp' );
  is( $cond->type, 'grouprn', 'grouprn type' );
  is( $cond->nparen, 3, 'grouprn nparen is 3' );
  is( $cond->visual, '(R3)', 'grouprn visual' );
}

{
  ok( $r->regex(q{(?(R&bar)a|b)}), "parse for grouprname accessor" );
  $r->parse;
  my $w = $r->walker;
  $w->(); # ifthen
  my ($cond) = $w->();
  is( $cond->family, 'groupp', 'grouprname family is groupp' );
  is( $cond->type, 'grouprname', 'grouprname type' );
  is( $cond->name, 'bar', 'grouprname name is bar' );
  is( $cond->visual, '(R&bar)', 'grouprname visual' );
}

__DATA__
0	assertion	ifthen	(?(R)a|b)
1	groupp	groupr	(R)
1	branch	branch	a|b
2	exact	exact	a
1	branch	branch
2	exact	exact	b
0	close	tail
DONE
0	open	open1	(a(?(R)a|(?1))a)
1	exact	exact	a
1	assertion	ifthen	(?(R)a|(?1))
2	groupp	groupr	(R)
2	branch	branch	a|(?1)
3	exact	exact	a
2	branch	branch
3	recurse	recurse	(?1)
1	close	tail
1	exact	exact	a
0	close	close1
DONE
0	open	open1	(a)
1	exact	exact	a
0	close	close1
0	assertion	ifthen	(?(R1)x|y)
1	groupp	grouprn	(R1)
1	branch	branch	x|y
2	exact	exact	x
1	branch	branch
2	exact	exact	y
0	close	tail
DONE
0	open	open1	(a)
1	exact	exact	a
0	close	close1
0	open	open2	(b)
1	exact	exact	b
0	close	close2
0	assertion	ifthen	(?(R2)x|y)
1	groupp	grouprn	(R2)
1	branch	branch	x|y
2	exact	exact	x
1	branch	branch
2	exact	exact	y
0	close	tail
DONE
0	open	open1	(?<foo>a)
1	exact	exact	a
0	close	close1
0	assertion	ifthen	(?(R&foo)x|b)
1	groupp	grouprname	(R&foo)
1	branch	branch	x|b
2	exact	exact	x
1	branch	branch
2	exact	exact	b
0	close	tail
DONE
