# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Parser.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 10;

use Regexp::Parser;

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $r = Regexp::Parser->new;

ok( $r->force_object(prop => "alpha", 0)->visual eq '\p{alpha}' );
ok( $r->regex('\N{LATIN SMALL LETTER R}') );
ok( $r->root->[0]->data, "r" );

$r = Regexp::Parser->new('[[:alpha:]]');
is($r->visual(), '[[:alpha:]]', "[[:alpha:]]");

# qr() portability: \N{NAME} should emit hex escapes, not \N{NAME} form
# (Perl's regex engine requires \N{NAME} to be resolved by the lexer,
# so runtime-compiled qr// patterns must use a portable representation)
$r = Regexp::Parser->new;
$r->regex('\N{LATIN SMALL LETTER A}');
my $qr_str = $r->root->[0]->qr;
like($qr_str, qr/\\x\{61\}/i, 'qr() for \\N{NAME} emits hex escape');
unlike($qr_str, qr/\\N\{/, 'qr() for \\N{NAME} does not emit \\N{NAME}');

# Verify the qr// actually compiles and matches
my $qr = eval { $r->qr };
ok(!$@, 'qr() with \\N{NAME} compiles without error');
ok('a' =~ $qr, 'qr() with \\N{NAME} matches correctly');

# \N{NAME} inside character class
$r = Regexp::Parser->new;
$r->regex('[\N{LATIN SMALL LETTER B}]');
my $cc_qr = eval { $r->qr };
ok(!$@, 'qr() with \\N{NAME} in char class compiles');
ok('b' =~ $cc_qr, 'qr() with \\N{NAME} in char class matches');

