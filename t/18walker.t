use strict;
use warnings;

use Test::More;
use Regexp::Parser;

# Comprehensive walker tests covering all node families.
# The existing t/03walker.t only tests quantifiers on a single pattern.
# This file validates tree structure for groups, alternation, character
# classes, assertions, backreferences, flags, and modern constructs.

my $r = Regexp::Parser->new;

# Helper: walk a pattern, return arrayref of [depth, family, type, visual]
sub walk_pattern {
  my ($rx, @args) = @_;
  $r->regex($rx, @args) or return undef;
  my $w = $r->walker;
  my @nodes;
  while (my ($n, $d) = $w->()) {
    push @nodes, [$d, $n->family, $n->type, $n->visual];
  }
  return \@nodes;
}

# Helper: check a walked tree against expected structure
sub check_tree {
  my ($rx, $expected, $label) = @_;
  my $nodes = walk_pattern($rx);
  ok($nodes, "$label: parses") or return;
  is(scalar @$nodes, scalar @$expected, "$label: node count");
  for my $i (0 .. $#$expected) {
    my ($ed, $ef, $et, $ev) = @{ $expected->[$i] };
    last unless $nodes->[$i];
    my ($gd, $gf, $gt, $gv) = @{ $nodes->[$i] };
    is($gd, $ed, "$label node $i: depth $ed");
    is($gf, $ef, "$label node $i: family '$ef'");
    is($gt, $et, "$label node $i: type '$et'");
    if (defined $ev) {
      is($gv, $ev, "$label node $i: visual");
    }
  }
}

# --- Capturing groups ---
check_tree('(abc)', [
  [0, 'open',  'open1',  '(abc)'],
  [1, 'exact', 'exact',  'abc'],
  [0, 'close', 'close1', undef],
], 'capture group');

# --- Non-capturing groups ---
check_tree('(?:abc)', [
  [0, 'group', 'group', '(?:abc)'],
  [1, 'exact', 'exact', 'abc'],
  [0, 'close', 'tail',  undef],
], 'non-capturing group');

# --- Alternation ---
check_tree('a|b|c', [
  [0, 'branch', 'branch', 'a|b|c'],
  [1, 'exact',  'exact',  'a'],
  [0, 'branch', 'branch', undef],
  [1, 'exact',  'exact',  'b'],
  [0, 'branch', 'branch', undef],
  [1, 'exact',  'exact',  'c'],
], 'alternation');

# --- Alternation in group ---
check_tree('(?:x|y)', [
  [0, 'group',  'group',  '(?:x|y)'],
  [1, 'branch', 'branch', 'x|y'],
  [2, 'exact',  'exact',  'x'],
  [1, 'branch', 'branch', undef],
  [2, 'exact',  'exact',  'y'],
  [0, 'close',  'tail',   undef],
], 'alternation in group');

# --- Character class ---
check_tree('[abc]', [
  [0, 'anyof', 'anyof',      '[abc]'],
  [1, 'anyof_char', 'anyof_char', undef],
  [1, 'anyof_char', 'anyof_char', undef],
  [1, 'anyof_char', 'anyof_char', undef],
  [0, 'close', 'anyof_close', undef],
], 'character class');

# --- Character class with range ---
check_tree('[a-z]', [
  [0, 'anyof',       'anyof',       '[a-z]'],
  [1, 'anyof_range', 'anyof_range', 'a-z'],
  [0, 'close',       'anyof_close', undef],
], 'character class range');

# --- Negated character class with shorthand ---
check_tree('[^\d]', [
  [0, 'anyof',       'anyof',  '[^\d]'],
  [1, 'anyof_class', 'digit',  '\d'],
  [0, 'close',       'anyof_close', undef],
], 'negated class with \\d');

# --- Lookahead ---
check_tree('(?=foo)', [
  [0, 'assertion', 'ifmatch', '(?=foo)'],
  [1, 'exact',     'exact',   'foo'],
  [0, 'close',     'tail',    undef],
], 'positive lookahead');

# --- Negative lookahead ---
check_tree('(?!bar)', [
  [0, 'assertion', 'unlessm', '(?!bar)'],
  [1, 'exact',     'exact',   'bar'],
  [0, 'close',     'tail',    undef],
], 'negative lookahead');

# --- Lookbehind ---
check_tree('(?<=x)', [
  [0, 'assertion', 'ifmatch', '(?<=x)'],
  [1, 'exact',     'exact',   'x'],
  [0, 'close',     'tail',    undef],
], 'positive lookbehind');

# --- Negative lookbehind ---
check_tree('(?<!y)', [
  [0, 'assertion', 'unlessm', '(?<!y)'],
  [1, 'exact',     'exact',   'y'],
  [0, 'close',     'tail',    undef],
], 'negative lookbehind');

# --- Atomic group ---
check_tree('(?>abc)', [
  [0, 'assertion', 'suspend', '(?>abc)'],
  [1, 'exact',     'exact',   'abc'],
  [0, 'close',     'tail',    undef],
], 'atomic group');

# --- Backreference ---
check_tree('(a)\1', [
  [0, 'open',  'open1',  '(a)'],
  [1, 'exact', 'exact',  'a'],
  [0, 'close', 'close1', undef],
  [0, 'ref',   'ref1',   '\1'],
], 'backreference');

# --- Named capture ---
check_tree('(?<name>x)', [
  [0, 'open',  'open1',  '(?<name>x)'],
  [1, 'exact', 'exact',  'x'],
  [0, 'close', 'close1', undef],
], 'named capture');

# --- Conditional ---
check_tree('(?(1)y|n)', [
  [0, 'assertion', 'ifthen',  '(?(1)y|n)'],
  [1, 'groupp',    'groupp1', '(1)'],
  [1, 'branch',    'branch',  'y|n'],
  [2, 'exact',     'exact',   'y'],
  [1, 'branch',    'branch',  undef],
  [2, 'exact',     'exact',   'n'],
  [0, 'close',     'tail',    undef],
], 'conditional');

# --- Conditional without else ---
check_tree('(?(1)y)', [
  [0, 'assertion', 'ifthen',  '(?(1)y)'],
  [1, 'groupp',    'groupp1', '(1)'],
  [1, 'branch',    'branch',  'y'],
  [2, 'exact',     'exact',   'y'],
  [0, 'close',     'tail',    undef],
], 'conditional no else');

# --- Flags in group ---
check_tree('(?i:abc)', [
  [0, 'group', 'group',  '(?i:abc)'],
  [1, 'exact', 'exactf', 'abc'],
  [0, 'close', 'tail',   undef],
], 'flag group (?i:)');

# --- Caret flags ---
check_tree('(?^:abc)', [
  [0, 'group', 'group', '(?^:abc)'],
  [1, 'exact', 'exact', 'abc'],
  [0, 'close', 'tail',  undef],
], 'caret flag group');

# --- Anchors ---
check_tree('^\w+$', [
  [0, 'anchor', 'bol',  '^'],
  [0, 'quant',  'plus', '\w+'],
  [1, 'alnum',  'alnum', '\w'],
  [0, 'anchor', 'eol',  '$'],
], 'anchors ^ and $');

# --- \b word boundary ---
check_tree('\bfoo\b', [
  [0, 'anchor', 'bound', '\b'],
  [0, 'exact',  'exact', 'foo'],
  [0, 'anchor', 'bound', '\b'],
], 'word boundaries');

# --- \K keep ---
check_tree('foo\Kbar', [
  [0, 'exact',  'exact', 'foo'],
  [0, 'anchor', 'keep',  '\K'],
  [0, 'exact',  'exact', 'bar'],
], '\\K keep');

# --- Unicode property ---
check_tree('\p{Letter}', [
  [0, 'prop', 'Letter', '\p{Letter}'],
], 'Unicode property');

# --- Negated Unicode property ---
check_tree('\P{Digit}', [
  [0, 'prop', 'Digit', '\P{Digit}'],
], 'negated Unicode property');

# --- \R linebreak ---
check_tree('\R', [
  [0, 'lnbreak', 'lnbreak', '\R'],
], '\\R linebreak');

# --- Possessive quantifier ---
check_tree('a++', [
  [0, 'possessive', 'possessive', 'a++'],
  [1, 'quant',      'plus',       'a+'],
  [2, 'exact',      'exact',      'a'],
], 'possessive quantifier');

# --- Branch reset ---
check_tree('(?|(a)|(b))', [
  [0, 'group',  'branch_reset', '(?|(a)|(b))'],
  [1, 'branch', 'branch',       '(a)|(b)'],
  [2, 'open',   'open1',        '(a)'],
  [3, 'exact',  'exact',        'a'],
  [2, 'close',  'close1',       undef],
  [1, 'branch', 'branch',       undef],
  [2, 'open',   'open2',        '(b)'],
  [3, 'exact',  'exact',        'b'],
  [2, 'close',  'close2',       undef],
  [0, 'close',  'tail',         undef],
], 'branch reset');

# --- Recursive pattern ---
check_tree('(?R)', [
  [0, 'recurse', 'recurse', '(?R)'],
], 'recursive (?R)');

# --- Backtracking verbs ---
check_tree('(*FAIL)', [
  [0, 'verb', 'FAIL', '(*FAIL)'],
], 'verb (*FAIL)');

# --- Nested groups ---
check_tree('(a(b)c)', [
  [0, 'open',  'open1',  '(a(b)c)'],
  [1, 'exact', 'exact',  'a'],
  [1, 'open',  'open2',  '(b)'],
  [2, 'exact', 'exact',  'b'],
  [1, 'close', 'close2', undef],
  [1, 'exact', 'exact',  'c'],
  [0, 'close', 'close1', undef],
], 'nested captures');

# --- Quantified group ---
check_tree('(?:ab)+', [
  [0, 'quant', 'plus',  '(?:ab)+'],
  [1, 'group', 'group', '(?:ab)'],
  [2, 'exact', 'exact', 'ab'],
  [1, 'close', 'tail',  undef],
], 'quantified non-capturing group');

# --- Complex: email-like pattern ---
check_tree('\w+@\w+\.\w+', [
  [0, 'quant', 'plus',  '\w+'],
  [1, 'alnum', 'alnum', '\w'],
  [0, 'exact', 'exact', '@'],
  [0, 'quant', 'plus',  '\w+'],
  [1, 'alnum', 'alnum', '\w'],
  [0, 'exact', 'exact', '\.'],
  [0, 'quant', 'plus',  '\w+'],
  [1, 'alnum', 'alnum', '\w'],
], 'email-like pattern');

# --- Walker depth parameter ---
{
  $r->regex('(a(b)c)');

  # depth 0: only top-level nodes
  my $w0 = $r->walker(0);
  my @d0;
  while (my ($n, $d) = $w0->()) {
    push @d0, $n->family;
  }
  is_deeply(\@d0, ['open', 'close'], 'walker(0): top-level only');

  # depth 1: one level deep
  my $w1 = $r->walker(1);
  my @d1;
  while (my ($n, $d) = $w1->()) {
    push @d1, [$d, $n->family];
  }
  my @expected_d1 = (
    [0, 'open'], [1, 'exact'], [1, 'open'], [1, 'close'],
    [1, 'exact'], [0, 'close'],
  );
  is_deeply(\@d1, \@expected_d1, 'walker(1): depth-limited');

  # default depth (-1): all nodes
  my $wall = $r->walker;
  my $count = 0;
  $count++ while $wall->();
  is($count, 7, 'walker(-1): all 7 nodes');
}

# --- Walker on pattern with no real content ---
{
  $r->regex('(?:)');
  my $w = $r->walker;
  my @nodes;
  while (my ($n, $d) = $w->()) {
    push @nodes, [$n->family, $n->type];
  }
  # (?:) produces group + tail
  is($nodes[0][0], 'group', 'empty group: group node');
  is($nodes[-1][1], 'tail', 'empty group: tail close');
}

# --- Walker on single character ---
{
  my $nodes = walk_pattern('x');
  is(scalar @$nodes, 1, 'single char: one node');
  is($nodes->[0][1], 'exact', 'single char: exact family');
}

# --- Script run (Perl 5.28+) ---
SKIP: {
  skip "script_run requires Perl 5.28+", 3 unless $] >= 5.028;
  check_tree('(*script_run:abc)', [
    [0, 'assertion', 'script_run', '(*script_run:abc)'],
    [1, 'exact',     'exact',      'abc'],
    [0, 'close',     'tail',       undef],
  ], 'script run');
}

# --- Extended character class (Perl 5.18+) ---
SKIP: {
  skip "extended charclass requires Perl 5.18+", 2 unless $] >= 5.018;
  my $nodes = walk_pattern('(?[\w])');
  ok($nodes, 'extended charclass parses');
  is($nodes->[0][1], 'charclass_expr', 'extended charclass: charclass_expr family');
}

done_testing;
