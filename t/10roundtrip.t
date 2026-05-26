use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Round-trip test: parse a regex, get visual(), re-parse that, get visual() again.
# The two visual() outputs must match.

my @patterns = (
    # Literals and anchors
    'abc',
    '^abc$',
    '\Aabc\z',
    '\Aabc\Z',
    '\bword\b',
    '\Bfoo\B',
    '\Gfoo',

    # Quantifiers
    'a+',
    'a*',
    'a?',
    'a{3}',
    'a{3,}',
    'a{3,5}',
    'a+?',
    'a*?',
    'a??',
    'a{3,5}?',

    # Dot and character classes
    '.',
    'a.b',
    '[abc]',
    '[a-z]',
    '[^abc]',
    '[^a-z]',
    '[\w\d\s]',
    '[\W\D\S]',
    '[\f\b\a]',
    '[\t\n\r]',
    '[\e]',

    # Shorthand classes
    '\w+',
    '\W+',
    '\d+',
    '\D+',
    '\s+',
    '\S+',

    # Escape sequences
    '\a\e\f\n\r\t',
    '\x41',
    '\x{41}',
    '\c@',
    '\cA',

    # Groups - non-capturing
    '(?:abc)',
    '(?:a|b|c)',
    '(?:a(?:b(?:c)))',

    # Groups - capturing
    '(abc)',
    '(a)(b)(c)',
    '(a(b)c)',
    '(a|b)',
    '((a|b)(c|d))',

    # Alternation
    'a|b',
    'a|b|c',
    'abc|def|ghi',
    'a(b|c)d',

    # Flags
    '(?i:abc)',
    '(?s:abc)',
    '(?m:abc)',
    '(?x:abc)',
    '(?im:abc)',
    '(?-i:abc)',
    '(?i-m:abc)',
    '(?i)',
    '(?-i)',

    # Assertions - lookahead
    '(?=abc)',
    '(?!abc)',
    'a(?=b)c',
    'a(?!b)c',

    # Assertions - lookbehind
    '(?<=abc)',
    '(?<!abc)',

    # Atomic groups
    '(?>abc)',
    '(?>a|b)',

    # Backreferences
    '(a)\1',
    '(a)(b)\2',

    # Conditional
    '(?(?=a)b|c)',
    '(?(?!a)b|c)',
    '(?(?<=a)b|c)',
    '(?(?<!a)b|c)',
    '(?(?{1})c|d)',
    '(?(1)b|c)',

    # Comments
    '(?#comment)abc',
    'a(?#mid)b',

    # Code evaluation
    '(?{1})',
    '(??{1})',

    # Unicode properties
    '\p{alpha}',
    '\P{alpha}',

    # POSIX classes in character class
    '[[:alpha:]]',
    '[[:digit:]]',
    '[[:^alpha:]]',

    # Complex combinations
    '^(\w+)\s*=\s*(.+)$',
    '(?:(?:a|b)+(?:c|d)*)',
    '(?i:a(?-i:b)c)',
    '(a+)(b+)\2\1',
    '[\w\-\.]+',
    # '^[a-zA-Z0-9_.+-]+$',  # dash before ] — known issue #6, PR #10

    # Named characters
    '\N{LATIN SMALL LETTER A}',

    # Clump
    '\X+',

    # Quantified groups
    '(abc)+',
    '(?:abc){2,5}',
    '(a|b)*?',
    '(?>abc)+',

    # Backreferences — relative and named
    '(a)\\g{1}',
    '(a)\\g1',
    '(a)(b)\\g{-1}',
    '(a)\\g{+1}(b)',
    '(a)(b)\\g{+1}(c)',
    '(?<foo>bar)\\k<foo>',
    "(?<foo>bar)\\k'foo'",
    '(?<foo>bar)\\k{foo}',
    '(?<x>a)(?P=x)',

    # Possessive quantifiers (Perl 5.10+)
    'a++',
    'a*+',
    'a?+',
    'a{3,5}+',
    '(a+b)++',
    '(?:a|b)*+',

    # Caret flag syntax (Perl 5.14+)
    '(?^:abc)',
    '(?^i:abc)',
    '(?^ims:abc)',
    '(?^imsx:abc)',

    # Named captures — (?P<name>...) syntax (normalizes to (?<name>...))
    '(?P<foo>abc)',
    '(?<bar>x)(?P<baz>y)',

    # Additional named backreferences
    '(?<n>a)\\k<n>',
    "(?<n>a)\\k'n'",

    # Recursive patterns (Perl 5.10+)
    '(?R)',
    'a(?R)?b',
    '(a(?1)?b)',
    '(?<pair>a(?&pair)?b)',
    '(?<x>a)(?P>x)',

    # Backtracking control verbs (Perl 5.10+)
    '(*FAIL)',
    '(*F)',
    '(*ACCEPT)',
    '(*SKIP)',
    '(*SKIP:label)',
    '(*MARK:name)',
    '(*PRUNE)',
    '(*PRUNE:tag)',
    '(*COMMIT)',
    '(*THEN)',
    '(*THEN:alt)',

    # Verbs in context
    'a(*THEN)b|c(*FAIL)',
    '(?:a(*SKIP:x)b|c)',

    # Alphabetic assertions (Perl 5.28+) — normalize to standard syntax
    '(*script_run:abc)',
    '(*asr:abc)',

    # Branch reset (Perl 5.10+)
    '(?|a)',
    '(?|(a)|(b))',
    '(?|(a)b|(c)(d))',
    '(?|foo|bar)',

    # Keep (Perl 5.10+)
    '\\K',
    'foo\\Kbar',

    # Linebreak (Perl 5.10+)
    '\\R',
    '\\R+',

    # Horizontal/vertical whitespace (Perl 5.10+)
    '\\h',
    '\\H',
    '\\v',
    '\\V',
    '[\\h\\v]',
    '\\h+\\v+',

    # Extended boundary types (Perl 5.22+)
    '\\b{wb}',
    '\\b{gcb}',
    '\\b{sb}',
    '\\b{lb}',
    '\\B{wb}',

    # Octal escapes (Perl 5.14+)
    '\\o{101}',
    '\\o{177}',
    '[\\o{60}-\\o{71}]',

    # Quotemeta (\\Q...\\E)
    '\\Qabc.def\\E',
    '\\Q[test]\\E',
    'foo\\Q.+*\\Ebar',

    # (?(DEFINE)...) groups (Perl 5.10+)
    '(?(DEFINE)(?<a>x))',
    '(?(DEFINE)(?<digit>\\d+)(?<word>\\w+))',

    # Named conditionals — angle bracket and quote forms
    '(a)(?(<a>)b|c)',
    "(a)(?('a')b|c)",

    # Numeric conditionals with captures
    '(a)(?(1)b|c)',
    '(x)(y)(?(2)a|b)',

    # Extended character classes (Perl 5.18+)
    '(?[\\d])',

    # Flag interactions
    '(?i:(?-i:a)(?i:b))',
    '(?i:(?-i:a))',
    '(?a:abc)',
    '(?d:abc)',
    '(?l:abc)',
    '(?u:abc)',
    '(?n:abc)',
    '(?aa:abc)',

    # Empty alternation branches
    '(a|)',
    '(|b)',
    '(|)',

    # Nested structures
    '(?=(?=a))',
    '(?:(?:(?:a)))',
    '(?:a|(?:b|c))',

    # Complex real-world-like patterns
    '(?<n>a)\\k<n>(?(<n>)b|c)',
    '(a(b)c)\\2',
    '(?:a+)+',
    '(a+?)+?',
    '(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)\\10',
    '[\\p{alpha}\\d]',
    '[\\P{alpha}]',
    '[[:alpha:][:digit:]]',
    '[^[:alpha:]]',
    '\\N{LATIN SMALL LETTER A}+',
    '[\\N{LATIN SMALL LETTER A}]',
    '(?{1})a',
    '(??{1})b',
);

# Normalization tests: syntactic sugar forms that parse correctly
# but normalize to canonical equivalents on visual() output
my @normalizations = (
    # Alphabetic assertions normalize to traditional syntax
    ['(*pla:abc)',  '(?=abc)',   'alpha positive lookahead'],
    ['(*nla:abc)',  '(?!abc)',   'alpha negative lookahead'],
    ['(*plb:abc)',  '(?<=abc)',  'alpha positive lookbehind'],
    ['(*nlb:abc)',  '(?<!abc)',  'alpha negative lookbehind'],
    ['(*atomic:abc)', '(?>abc)', 'alpha atomic group'],
    ['(*sr:abc)',   '(*script_run:abc)', 'sr shorthand'],

    # Python-style named capture normalizes
    ['(?P<foo>abc)',   '(?<foo>abc)',  'Python named capture'],
    # Curly quantifiers that simplify
    ['a{0,}',  'a*',     'curly to star'],
    ['a{1,}',  'a+',     'curly to plus'],
    ['a{0,1}', 'a?',     'curly to optional'],
    ['a{1,1}', 'a{1}',   'curly singleton'],
);

plan tests => scalar(@patterns) * 2 + scalar(@normalizations) * 2;

for my $pat (@patterns) {
    my $r1 = Regexp::Parser->new;
    my $ok1 = $r1->regex($pat);
    if (!$ok1) {
        fail("parse '$pat': " . ($r1->errmsg || 'unknown error'));
        fail("roundtrip '$pat': skipped");
        next;
    }
    my $vis1 = $r1->visual;
    pass("parse '$pat'");

    # Round-trip: re-parse the visual output
    my $r2 = Regexp::Parser->new;
    my $ok2 = $r2->regex($vis1);
    if (!$ok2) {
        fail("roundtrip '$pat' -> '$vis1': " . ($r2->errmsg || 'unknown error'));
        next;
    }
    my $vis2 = $r2->visual;
    is($vis2, $vis1, "roundtrip '$pat'");
}

# Normalization: verify sugar forms parse and normalize correctly
for my $n (@normalizations) {
    my ($input, $expected, $desc) = @$n;
    my $r = Regexp::Parser->new;
    my $ok = $r->regex($input);
    if (!$ok) {
        fail("parse normalize '$desc': " . ($r->errmsg || 'unknown error'));
        fail("normalize '$desc': skipped");
        next;
    }
    my $vis = $r->visual;
    pass("parse normalize '$desc'");
    is($vis, $expected, "normalize '$desc': $input -> $expected");
}
