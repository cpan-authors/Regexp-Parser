use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Functional test: parse a regex, produce qr//, verify match behavior.
# This tests the full pipeline: source → parse → tree → qr() → match.

my @tests = (
    # [pattern, test_string, should_match, description, min_perl_version]
    # min_perl_version is optional; when present, the test is skipped on older Perls

    # Literals
    ['abc',       'abc',   1, 'literal match'],
    ['abc',       'def',   0, 'literal non-match'],

    # Anchors
    ['^abc$',     'abc',   1, 'anchored match'],
    ['^abc$',     'xabc',  0, 'anchored non-match'],
    ['\Aabc\z',   'abc',   1, '\A \z anchors'],

    # Quantifiers
    ['a+',        'aaa',   1, 'plus quantifier'],
    ['a+',        '',      0, 'plus needs at least one'],
    ['a*',        '',      1, 'star matches empty'],
    ['a?',        'b',     1, 'question matches empty'],
    ['a{3}',      'aaa',   1, 'exact count'],
    ['a{3}',      'aa',    0, 'exact count too few'],
    ['a{2,4}',    'aaa',   1, 'range quantifier'],
    ['a+?',       'aaa',   1, 'lazy plus'],
    ['a{2,5}?',   'aaaa',  1, 'lazy range'],

    # Possessive quantifiers
    ['a++b',      'aab',   1, 'possessive plus match'],
    ['a*+b',      'aab',   1, 'possessive star match'],

    # Character classes
    ['[abc]',     'b',     1, 'char class match'],
    ['[abc]',     'd',     0, 'char class non-match'],
    ['[^abc]',    'd',     1, 'negated class match'],
    ['[^abc]',    'a',     0, 'negated class non-match'],
    ['[a-z]',     'm',     1, 'range class'],
    ['[a-z]',     'A',     0, 'range class case mismatch'],

    # Shorthand classes
    ['\d+',       '123',   1, '\d matches digits'],
    ['\d+',       'abc',   0, '\d rejects letters'],
    ['\w+',       'hello', 1, '\w matches word chars'],
    ['\s+',       '   ',   1, '\s matches whitespace'],
    ['\D',        'x',     1, '\D matches non-digit'],
    ['\W',        '!',     1, '\W matches non-word'],
    ['\S',        'x',     1, '\S matches non-space'],

    # Dot
    ['a.b',       'axb',   1, 'dot matches any char'],
    ['a.b',       "a\nb",  0, 'dot skips newline by default'],

    # Alternation
    ['a|b',       'a',     1, 'alternation first'],
    ['a|b',       'b',     1, 'alternation second'],
    ['a|b',       'c',     0, 'alternation non-match'],
    ['abc|def',   'def',   1, 'multi-char alternation'],

    # Groups - non-capturing
    ['(?:abc)+',  'abcabc', 1, 'quantified nc group'],
    ['(?:a|b)c',  'ac',     1, 'nc group with alternation'],
    ['(?:a|b)c',  'bc',     1, 'nc group alt second branch'],

    # Groups - capturing
    ['(a)(b)\2',    'abb',   1, 'backref match'],
    ['(a)(b)\2',    'abc',   0, 'backref non-match'],
    ['(a+)(b+)\2',  'aabbb', 1, 'backref with quantifiers'],

    # Flags
    ['(?i:abc)',    'ABC',   1, 'case-insensitive flag'],
    ['(?i:abc)',    'abc',   1, 'case-insensitive lowercase too'],
    ['(?s:a.b)',    "a\nb",  1, 'single-line (dotall) flag'],
    ['(?i)abc',     'ABC',   1, 'flag-only toggle'],

    # Caret flags
    ['(?^:abc)',    'abc',   1, 'caret flag basic'],
    ['(?^i:abc)',   'ABC',   1, 'caret flag with i'],

    # Lookahead
    ['(?=foo)foo',  'foo',   1, 'positive lookahead'],
    ['(?!bar)foo',  'foo',   1, 'negative lookahead match'],
    ['(?!foo)foo',  'foo',   0, 'negative lookahead non-match'],

    # Lookbehind
    ['(?<=a)b',     'ab',    1, 'positive lookbehind'],
    ['(?<!a)b',     'xb',    1, 'negative lookbehind match'],
    ['(?<!a)b',     'ab',    0, 'negative lookbehind non-match'],

    # Atomic group
    ['(?>abc)',     'abc',   1, 'atomic group match'],

    # Named captures
    ['(?<n>abc)\k<n>',  'abcabc',  1, 'named capture + backref'],
    ['(?<n>abc)\k<n>',  'abcdef',  0, 'named capture backref non-match'],
    ["(?<n>abc)\\k'n'", 'abcabc',  1, 'named capture single-quote backref'],
    ['(?P<n>x)(?P=n)',  'xx',      1, 'Python named capture'],

    # Branch reset
    ['(?|(a)|(b))',  'a',    1, 'branch reset first alt'],
    ['(?|(a)|(b))',  'b',    1, 'branch reset second alt'],
    ['(?|(a)|(b))',  'c',    0, 'branch reset non-match'],

    # Backtracking verbs
    ['(*FAIL)',      'x',    0, 'FAIL always fails'],
    ['a(*ACCEPT)b',  'a',    1, 'ACCEPT succeeds early'],

    # \K (keep)
    ['foo\Kbar',    'foobar', 1, '\K in match context'],

    # Script run (Perl 5.30+; verb not recognized by older regex engines)
    ['(*sr:\d+)',   '123',   1, 'script_run match', 5.030],

    # Quotemeta
    ['\Qa.b\E',    'a.b',   1, 'quotemeta literal dot'],
    ['\Qa.b\E',    'axb',   0, 'quotemeta rejects wildcard'],

    # Unicode properties
    ['\p{Lu}',     'A',     1, 'uppercase property'],
    ['\P{Lu}',     'a',     1, 'negated uppercase property'],

    # POSIX classes
    ['[[:alpha:]]',  'a',   1, 'POSIX alpha'],
    ['[[:digit:]]',  '5',   1, 'POSIX digit'],
    ['[[:^alpha:]]', '5',   1, 'POSIX negated alpha'],

    # \R, \h, \v, \X
    ['\R',          "\n",   1, '\R matches newline'],
    ['\h',          ' ',    1, '\h matches space'],
    ['\H',          'x',    1, '\H matches non-hspace'],
    ['\v',          "\n",   1, '\v matches vertical space'],
    ['\V',          'x',    1, '\V matches non-vspace'],
    ['\X',          'a',    1, '\X matches grapheme cluster'],

    # Conditional
    ['(?(1)a|b)',   'b',    1, 'conditional false branch'],

    # Named characters (\N{NAME} in runtime qr// requires 5.30+; older Perls
    # demand lexer-time resolution that can't happen in a string-built pattern)
    ['\N{LATIN SMALL LETTER A}', 'a', 1, 'named character', 5.030],

    # Hex and control escapes
    ['\x41',        'A',    1, 'hex escape'],
    ['\x{41}',      'A',    1, 'braced hex escape'],
    ['\cA',         "\x01", 1, 'control char'],

    # Escape sequences
    ['\t',          "\t",   1, 'tab escape'],
    ['\n',          "\n",   1, 'newline escape'],
    ['\r',          "\r",   1, 'return escape'],
);

plan tests => scalar @tests;

for my $t (@tests) {
    my ($pat, $str, $expect, $desc, $min_perl) = @$t;

    if ($min_perl && $] < $min_perl) {
        my $need = sprintf("%.3f", $min_perl);
        SKIP: {
            skip "$desc requires Perl $need (have $])", 1;
        }
        next;
    }

    my $r = Regexp::Parser->new;
    my $ok = $r->regex($pat);
    unless (defined $ok) {
        fail("$desc: parse failed for '$pat'");
        next;
    }

    my $qr = eval { $r->qr };
    if ($@) {
        fail("$desc: qr() died: $@");
        next;
    }
    unless (defined $qr) {
        fail("$desc: qr() returned undef");
        next;
    }

    my $got = eval { $str =~ $qr ? 1 : 0 };
    if ($@) {
        fail("$desc: match died: $@");
        next;
    }

    if ($expect) {
        ok($got, $desc);
    }
    else {
        ok(!$got, $desc);
    }
}
