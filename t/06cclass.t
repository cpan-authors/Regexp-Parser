# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Parser.t'

use strict;
use warnings;

use Test::More tests => 29;
use Regexp::Parser;

my $r = Regexp::Parser->new;
my $rx = '[\f\b\a]+';
ok( $r->regex($rx), 'parse character class' );
is( $r->visual, '[\f\b\a]+', 'visual roundtrip' );

# rt.cpan.org #59854 / GitHub #6: dash at end of character class should be literal
# Perl treats a trailing dash as a literal hyphen, not a range operator

# trailing dash: [ _-]
$r = Regexp::Parser->new;
ok( $r->regex('[ _-]'), 'parse [ _-] succeeds' );
is( $r->visual, '[ _-]', 'visual for [ _-]' );

# trailing dash: [a-]
$r = Regexp::Parser->new;
ok( $r->regex('[a-]'), 'parse [a-] succeeds' );
is( $r->visual, '[a-]', 'visual for [a-]' );

# leading dash still works: [-a]
$r = Regexp::Parser->new;
ok( $r->regex('[-a]'), 'parse [-a] succeeds' );

# normal range still works: [a-z]
$r = Regexp::Parser->new;
ok( $r->regex('[a-z]'), 'parse [a-z] succeeds' );
is( $r->visual, '[a-z]', 'visual for [a-z]' );

# dash between two characters: [ -_]
$r = Regexp::Parser->new;
ok( $r->regex('[ -_]'), 'parse [ -_] succeeds' );
is( $r->visual, '[ -_]', 'visual for [ -_]' );

# RT#17075: character class range with large hex values should not
# be rejected as invalid when the range is actually valid.
# The bug was comparing visual string representations instead of
# numeric character values.
my $r2 = Regexp::Parser->new;
my $rx2 = '[\\x{EFFFE}-\\x{10FFFF}]';
ok( $r2->regex($rx2), 'parse large hex range' );
is( $r2->visual, '[\\x{EFFFE}-\\x{10FFFF}]', 'visual for large hex range' );

# Also test a simpler case where string comparison would fail:
# \x{FF} vs \x{100} -- "FF" gt "100" as strings but 0xFF < 0x100
my $r3 = Regexp::Parser->new;
my $rx3 = '[\\x{FF}-\\x{100}]';
ok( $r3->regex($rx3), 'parse hex range crossing string comparison boundary' );
is( $r3->visual, '[\\x{FF}-\\x{100}]', 'visual for hex range crossing string comparison boundary' );

# Octal escape ranges in character classes
# These crashed with "Can't call method visual on undefined value"
# because the \ handler used object() instead of force_object()
# for octal/unknown escapes in character class context.

# octal-to-octal range
my $r4 = Regexp::Parser->new;
ok( $r4->regex('[\\101-\\132]'), 'parse octal range [\\101-\\132]' );
is( $r4->visual, '[\\101-\\132]', 'visual for octal range A-Z' );

# short octal range
my $r5 = Regexp::Parser->new;
ok( $r5->regex('[\\60-\\71]'), 'parse octal range [\\60-\\71]' );
is( $r5->visual, '[\\060-\\071]', 'visual for octal range 0-9 (normalized)' );

# single-digit octal range
my $r6 = Regexp::Parser->new;
ok( $r6->regex('[\\1-\\7]'), 'parse octal range [\\1-\\7]' );
is( $r6->visual, '[\\001-\\007]', 'visual for single-digit octal range' );

# literal-to-octal range
my $r7 = Regexp::Parser->new;
ok( $r7->regex('[A-\\132]'), 'parse mixed range [A-\\132]' );
is( $r7->visual, '[A-\\132]', 'visual for literal-to-octal range' );

# octal-to-literal range
my $r8 = Regexp::Parser->new;
ok( $r8->regex('[\\101-Z]'), 'parse mixed range [\\101-Z]' );
is( $r8->visual, '[\\101-Z]', 'visual for octal-to-literal range' );

# hex-to-octal mixed range
my $r9 = Regexp::Parser->new;
ok( $r9->regex('[\\x41-\\132]'), 'parse hex-to-octal range' );
is( $r9->visual, '[\\x41-\\132]', 'visual for hex-to-octal range' );

# round-trip: parse visual output again
my $r10 = Regexp::Parser->new;
$r10->regex('[\\101-\\132]');
my $v = $r10->visual;
my $r11 = Regexp::Parser->new;
ok( $r11->regex($v), 'round-trip: re-parse octal range visual output' );
is( $r11->visual, $v, 'round-trip: visual is stable' );
