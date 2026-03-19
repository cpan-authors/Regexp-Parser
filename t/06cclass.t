# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Parser.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 16 };

use Regexp::Parser;
ok( 1 );

my $r = Regexp::Parser->new;
my $rx = '[\f\b\a]+';
ok( $r->regex($rx) );
ok( $r->visual, '[\f\b\a]+' );

# rt.cpan.org #59854 / GitHub #6: dash at end of character class should be literal
# Perl treats a trailing dash as a literal hyphen, not a range operator

# trailing dash: [ _-]
$r = Regexp::Parser->new;
ok( $r->regex('[ _-]'), 1, 'parse [ _-] succeeds' );
ok( $r->visual, '[ _-]', 'visual for [ _-]' );

# trailing dash: [a-]
$r = Regexp::Parser->new;
ok( $r->regex('[a-]'), 1, 'parse [a-] succeeds' );
ok( $r->visual, '[a-]', 'visual for [a-]' );

# leading dash still works: [-a]
$r = Regexp::Parser->new;
ok( $r->regex('[-a]'), 1, 'parse [-a] succeeds' );

# normal range still works: [a-z]
$r = Regexp::Parser->new;
ok( $r->regex('[a-z]'), 1, 'parse [a-z] succeeds' );
ok( $r->visual, '[a-z]', 'visual for [a-z]' );

# dash between two characters: [ -_]
$r = Regexp::Parser->new;
ok( $r->regex('[ -_]'), 1, 'parse [ -_] succeeds' );
ok( $r->visual, '[ -_]', 'visual for [ -_]' );

# RT#17075: character class range with large hex values should not
# be rejected as invalid when the range is actually valid.
# The bug was comparing visual string representations instead of
# numeric character values.
my $r2 = Regexp::Parser->new;
my $rx2 = '[\\x{EFFFE}-\\x{10FFFF}]';
ok( $r2->regex($rx2) );
ok( $r2->visual, '[\\x{EFFFE}-\\x{10FFFF}]' );

# Also test a simpler case where string comparison would fail:
# \x{FF} vs \x{100} -- "FF" gt "100" as strings but 0xFF < 0x100
my $r3 = Regexp::Parser->new;
my $rx3 = '[\\x{FF}-\\x{100}]';
ok( $r3->regex($rx3) );
ok( $r3->visual, '[\\x{FF}-\\x{100}]' );
