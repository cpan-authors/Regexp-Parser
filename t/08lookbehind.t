use strict;
use warnings;

use Test::More;

use Regexp::Parser;
use Regexp::Parser::Diagnostics;

my @should_reject = (
  ['(?<=a+)',             'plus in positive lookbehind'],
  ['(?<=a*)',             'star in positive lookbehind'],
  ['(?<=a{2,})',          'open-ended quantifier'],
  ['(?<=a+b)',            'unbounded then fixed'],
  ['(?<!a+)',             'plus in negative lookbehind'],
  ['(?<!a*)',             'star in negative lookbehind'],
  ['(?<=(?:a|bb)+)',      'quantified group alternation'],
);

my @should_accept = (
  ['(?<=a)',              'single char'],
  ['(?<=abc)',            'fixed string'],
  ['(?<=a{3})',           'exact quantifier'],
  ['(?<=a{2,4})',         'bounded quantifier'],
  ['(?<=a?)',             'optional (max 1)'],
  ['(?<=a|bc)',           'alternation'],
  ['(?<=a(?:b|cd))',      'group with alternation'],
  ['(?<=(?:ab){2})',      'quantified group'],
  ['(?<=\d)',             'digit shorthand'],
  ['(?<=\w)',             'word shorthand'],
  ['(?<=.)',              'dot metachar'],
  ['(?<=\p{Latin})',      'unicode property'],
  ['(?<=[abc])',          'character class'],
  ['(?<=(?=a)b)',         'lookahead inside lookbehind'],
  ['(?<=(?>abc))',        'atomic group in lookbehind'],
  ['(?<=(?:abc))',        'non-capture group'],
  ['(?<!abc)',            'negative fixed lookbehind'],
  ['(?<=a{255})',         'max length 255'],
);

my @boundary_reject = (
  ['(?<=a{256})',         '256 exceeds limit'],
  ['(?<=' . ('a' x 256) . ')', '256 literal chars'],
);

my @boundary_accept = (
  ['(?<=' . ('a' x 255) . ')', '255 literal chars'],
);

plan tests => @should_reject + @should_accept + @boundary_reject + @boundary_accept;

for my $case (@should_reject) {
  my ($pat, $desc) = @$case;
  my $p = Regexp::Parser->new;
  $p->regex($pat);
  my $vis = eval { $p->visual };
  ok(!defined $vis, "reject: $desc");
}

for my $case (@should_accept, @boundary_accept) {
  my ($pat, $desc) = @$case;
  my $p = Regexp::Parser->new;
  $p->regex($pat);
  my $vis = eval { $p->visual };
  ok(defined $vis, "accept: $desc");
}

for my $case (@boundary_reject) {
  my ($pat, $desc) = @$case;
  my $p = Regexp::Parser->new;
  $p->regex($pat);
  my $vis = eval { $p->visual };
  ok(!defined $vis, "reject: $desc");
}
