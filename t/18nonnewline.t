use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Tests for \N handling:
#   - \N bare = "not newline" (Perl 5.12+)
#   - \N{NAME} = named character
#   - \N{U+HHHH} = Unicode code point

my $r = Regexp::Parser->new;

##
## 1. Bare \N (not newline)
##

{
    my $ok = $r->regex('\N');
    ok($ok, '\\N bare parses successfully');
    is($r->visual, '\N', '\\N visual round-trips');

    # Check node type
    my $w = $r->walker;
    my $node = $w->();
    ok($node, '\\N produces a node');
    is($node->family, 'nonnewline', '\\N node family is nonnewline');
    is($node->type, 'nonnewline', '\\N node type is nonnewline');
    is($node->visual, '\N', '\\N node visual is \\N');
}

# \N in a larger pattern
{
    $r->regex('a\Nb');
    is($r->visual, 'a\Nb', '\\N in context: a\\Nb');
}

# \N with quantifiers
{
    $r->regex('\N+');
    is($r->visual, '\N+', '\\N+ (one or more non-newlines)');
}

{
    $r->regex('\N*');
    is($r->visual, '\N*', '\\N* (zero or more non-newlines)');
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $r->regex('\N{3,5}');
    is($r->visual, '\N{3,5}', '\\N{3,5} (quantifier, not named char)');
    is(scalar @warnings, 0, '\\N{3,5} produces no warnings');

    # Verify structure: quantifier wrapping nonnewline
    my $w = $r->walker;
    my $node = $w->();
    is($node->family, 'quant', '\\N{3,5} quantifier node present');
    my $inner = $w->();
    is($inner->family, 'nonnewline', '\\N{3,5} inner node is nonnewline');
}

# \N{3} is also a quantifier, not a named char
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $r->regex('\N{3}');
    is($r->visual, '\N{3}', '\\N{3} (exact quantifier)');
    is(scalar @warnings, 0, '\\N{3} produces no warnings');
}

# Round-trip: parse -> visual -> re-parse -> visual
{
    $r->regex('\N');
    my $v1 = $r->visual;
    $r->regex($v1);
    my $v2 = $r->visual;
    is($v2, $v1, '\\N round-trips correctly');
}

{
    $r->regex('^\N+$');
    my $v1 = $r->visual;
    $r->regex($v1);
    my $v2 = $r->visual;
    is($v2, $v1, '^\N+$ round-trips correctly');
}

##
## 2. \N{NAME} (named character)
##

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $r->regex('\N{SPACE}');
    is($r->visual, '\N{SPACE}', '\\N{SPACE} visual');
    is(scalar @warnings, 0, '\\N{SPACE} produces no warnings');
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $r->regex('\N{LATIN SMALL LETTER A}');
    is($r->visual, '\N{LATIN SMALL LETTER A}', '\\N{LATIN SMALL LETTER A} visual');
    is(scalar @warnings, 0, '\\N{LATIN SMALL LETTER A} no warnings');
}

##
## 3. \N{U+HHHH} (Unicode code point)
##

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $r->regex('\N{U+0041}');
    is($r->visual, '\N{U+0041}', '\\N{U+0041} visual');
    is(scalar @warnings, 0, '\\N{U+0041} produces no warnings');

    # Check the node contains the right character
    my $w = $r->walker;
    my $node = $w->();
    ok($node, '\\N{U+0041} produces a node');
    is($node->visual, '\N{U+0041}', '\\N{U+0041} node visual');
    is($node->data, 'A', '\\N{U+0041} resolves to "A"');
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $r->regex('\N{U+0020}');
    is($r->visual, '\N{U+0020}', '\\N{U+0020} visual (space)');
    is(scalar @warnings, 0, '\\N{U+0020} produces no warnings');

    my $w = $r->walker;
    my $node = $w->();
    is($node->data, ' ', '\\N{U+0020} resolves to space');
}

# \N{U+HHHH} inside character class
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $r->regex('[\N{U+0041}]');
    is($r->visual, '[\N{U+0041}]', '\\N{U+0041} in character class');
    is(scalar @warnings, 0, '\\N{U+0041} in char class no warnings');
}

# \N{U+HHHH} round-trip
{
    $r->regex('\N{U+0041}');
    my $v1 = $r->visual;
    $r->regex($v1);
    my $v2 = $r->visual;
    is($v2, $v1, '\\N{U+0041} round-trips correctly');
}

##
## 4. Error cases preserved
##

# \N bare inside character class is still an error
{
    my $ok = $r->regex('[\N]');
    ok(!$ok, '\\N bare inside character class is rejected');
}

# \N{ without closing brace
{
    my $ok = $r->regex('\N{SPACE');
    ok(!$ok, '\\N{SPACE (unclosed) is rejected');
}

done_testing;
