use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Tests for (?[...]) extended character class syntax (Perl 5.18+)

my $r = Regexp::Parser->new;

sub parse_ok {
    my ($input, $expected_vis, $desc) = @_;
    my $ok = $r->regex($input);
    ok($ok, "parse '$input'") or do {
        diag("error: " . ($r->errmsg || "unknown"));
        return;
    };
    is($r->visual, $expected_vis, $desc || "visual '$input'");
}

sub parse_tree_ok {
    my ($input, $expected_family, $expected_type, $desc) = @_;
    my $ok = $r->regex($input);
    ok($ok, "parse '$input'") or do {
        diag("error: " . ($r->errmsg || "unknown"));
        return;
    };
    my $t = $r->root;
    is(scalar @$t, 1, "$desc: single node") or return;
    is($t->[0]->family, $expected_family, "$desc: family");
    is($t->[0]->type, $expected_type, "$desc: type");
}

# === Basic extended character classes ===

parse_ok('(?[\d])',          '(?[\d])',            'simple digit class');
parse_ok('(?[\w])',          '(?[\w])',            'simple word class');
parse_ok('(?[\s])',          '(?[\s])',            'simple space class');

# === Set operations ===

parse_ok('(?[\d & \w])',     '(?[\d & \w])',       'intersection');
parse_ok('(?[\d + \w])',     '(?[\d + \w])',       'union');
parse_ok('(?[\w - \d])',     '(?[\w - \d])',       'subtraction');
parse_ok('(?[\d ^ \w])',     '(?[\d ^ \w])',       'symmetric difference');
parse_ok('(?[!\d])',         '(?[!\d])',           'complement');

# === Nested traditional character classes ===

parse_ok('(?[[a-z]])',       '(?[[a-z]])',         'nested traditional class');
parse_ok('(?[[^aeiou]])',    '(?[[^aeiou]])',      'nested negated class');
parse_ok('(?[[a-z] & [^aeiou]])', '(?[[a-z] & [^aeiou]])', 'intersection with nested classes');
parse_ok('(?[[a-z] - [aeiou]])',  '(?[[a-z] - [aeiou]])',  'subtraction with nested classes');

# === Unicode properties ===

parse_ok('(?[\p{Alpha}])',   '(?[\p{Alpha}])',     'Unicode property');
parse_ok('(?[\p{Thai} & \p{Digit}])', '(?[\p{Thai} & \p{Digit}])', 'property intersection');
parse_ok('(?[\p{Greek} + \p{Cyrillic}])', '(?[\p{Greek} + \p{Cyrillic}])', 'property union');

# === Parenthesized subexpressions ===

parse_ok('(?[(\p{Alpha} & \p{ASCII})])',
    '(?[(\p{Alpha} & \p{ASCII})])',
    'parenthesized subexpression');
parse_ok('(?[(\d + \w) & \p{ASCII}])',
    '(?[(\d + \w) & \p{ASCII}])',
    'mixed paren and operator');

# === With escapes ===

parse_ok('(?[\x20-\x7E])',  '(?[\x20-\x7E])',     'hex escapes');
parse_ok('(?[\t])',          '(?[\t])',             'tab escape');
parse_ok('(?[\\\\])',        '(?[\\\\])',           'literal backslash');

# === Tree structure ===

parse_tree_ok('(?[\d])', 'charclass_expr', 'charclass_expr', 'tree structure');

# === Data accessor ===

{
    $r->regex('(?[\d & \w])');
    my $t = $r->root;
    is($t->[0]->data, '\d & \w', 'data accessor returns expression content');
}

# === Embedded in larger patterns ===

parse_ok('^(?[\d])$',       '^(?[\d])$',          'anchored extended class');
parse_ok('a(?[\d])b',       'a(?[\d])b',          'between literals');
parse_ok('(?[\d])+',        '(?[\d])+',           'with quantifier');
parse_ok('(?[\d]){2,5}',    '(?[\d]){2,5}',       'with curly quantifier');
parse_ok('foo|(?[\d])',     'foo|(?[\d])',         'in alternation');

# === Round-trip stability ===
# Parse -> visual -> re-parse -> visual should be stable

{
    my @patterns = (
        '(?[\d])',
        '(?[\d & \w])',
        '(?[[a-z] - [aeiou]])',
        '(?[\p{Thai} & \p{Digit}])',
        '(?[(\p{Alpha} & \p{ASCII}) + \d])',
        '(?[!\d])',
        '(?[\d + \w - \s])',
    );
    for my $pat (@patterns) {
        $r->regex($pat);
        my $vis1 = $r->visual;
        $r->regex($vis1);
        my $vis2 = $r->visual;
        is($vis2, $vis1, "round-trip: $pat");
    }
}

# === Comments inside extended char classes ===
# (?[...]) is always /x-like, so # starts a comment

parse_ok("(?[\\d # digits only\n])", "(?[\\d # digits only\n])", 'comment in extended class');

# === Complex expressions ===

parse_ok('(?[[\x00-\x7F] - [\x00-\x1F] - [\x7F]])',
    '(?[[\x00-\x7F] - [\x00-\x1F] - [\x7F]])',
    'printable ASCII via subtraction');

parse_ok('(?[(\p{Word} & \p{ASCII}) + [_]])',
    '(?[(\p{Word} & \p{ASCII}) + [_]])',
    'ASCII word chars plus underscore');

done_testing;
