# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Parser.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 12 };

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
