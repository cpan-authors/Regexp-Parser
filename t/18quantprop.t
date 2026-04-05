use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Tests for {,n} quantifier syntax (Perl 5.34+) and \p{^Name} negation

my $r = Regexp::Parser->new;

# --- {,n} quantifier (Perl 5.34+): upper bound only, min=0 ---

subtest '{,n} quantifier basics' => sub {
    $r->regex('a{,5}');
    my $vis = $r->visual;
    # {,n} normalizes to {0,n} in visual output
    is($vis, 'a{0,5}', '{,5} parses as quantifier (normalizes to {0,5})');

    my @nodes = @{ $r->root };
    # quant wraps the exact node — root has 1 top-level quant node
    is(scalar @nodes, 1, '{,5} produces one top-level node');
    is($nodes[0]->family, 'quant', 'top-level node is quant');
    is($nodes[0]->{min}, 0, 'quant min is 0');
    is($nodes[0]->{max}, 5, 'quant max is 5');
};

subtest '{,n} with different values' => sub {
    for my $n (1, 2, 10, 100) {
        $r->regex("x{,$n}");
        my @nodes = @{ $r->root };
        is($nodes[0]->family, 'quant', "{,$n} produces quant node");
        is($nodes[0]->{min}, 0, "{,$n} min is 0");
        is($nodes[0]->{max}, $n, "{,$n} max is $n");
    }
};

subtest '{,n} with lazy and possessive modifiers' => sub {
    $r->regex('a{,3}?');
    is($r->visual, 'a{0,3}?', '{,3}? parses with lazy modifier');

    $r->regex('a{,3}+');
    is($r->visual, 'a{0,3}+', '{,3}+ parses with possessive modifier');
};

subtest '{,n} in groups and classes' => sub {
    $r->regex('(?:ab){,2}');
    is($r->visual, '(?:ab){0,2}', '{,n} works on groups');

    $r->regex('[abc]{,4}');
    is($r->visual, '[abc]{0,4}', '{,n} works on character classes');
};

subtest '{,n} round-trip' => sub {
    for my $pat ('a{,5}', 'x{,1}', '(?:ab){,3}', 'a{,5}?', 'a{,5}+') {
        $r->regex($pat);
        my $vis1 = $r->visual;
        # Re-parse the normalized output
        $r->regex($vis1);
        my $vis2 = $r->visual;
        is($vis2, $vis1, "round-trip: $pat -> $vis1");
    }
};

subtest '{,n} not confused with literal' => sub {
    # {,} without digits should still be literal
    $r->regex('a{,}');
    is($r->visual, 'a{,}', '{,} without digits is literal');

    # {,0} is valid — matches zero times
    $r->regex('a{,0}');
    my @nodes = @{ $r->root };
    is($nodes[0]->family, 'quant', '{,0} is a valid quantifier');
    is($nodes[0]->{min}, 0, '{,0} min is 0');
    is($nodes[0]->{max}, 0, '{,0} max is 0');
};

# --- \p{^Name} property negation ---

subtest '\\p{^Name} negation' => sub {
    $r->regex('\\p{^Greek}');
    my @nodes = @{ $r->root };
    is(scalar @nodes, 1, '\\p{^Greek} produces one node');
    is($nodes[0]->family, 'prop', 'node is a prop');
    is($nodes[0]->type, 'Greek', 'type is Greek (without ^)');
    is($nodes[0]->neg, 1, 'neg flag is set');
    is($nodes[0]->visual, '\\P{Greek}', '\\p{^Greek} normalizes to \\P{Greek}');
};

subtest '\\p{^Name} vs \\P{Name} equivalence' => sub {
    $r->regex('\\p{^Alpha}');
    my @n1 = @{ $r->root };

    $r->regex('\\P{Alpha}');
    my @n2 = @{ $r->root };

    is($n1[0]->neg, $n2[0]->neg, 'same neg flag');
    is($n1[0]->type, $n2[0]->type, 'same type');
    is($n1[0]->visual, $n2[0]->visual, 'same visual output');
};

subtest '\\p{Name} without ^ is still positive' => sub {
    $r->regex('\\p{Greek}');
    my @nodes = @{ $r->root };
    is($nodes[0]->neg, 0, '\\p{Greek} neg is 0');
    is($nodes[0]->type, 'Greek', 'type is Greek');
    is($nodes[0]->visual, '\\p{Greek}', 'visual is \\p{Greek}');
};

subtest '\\p{^Name} in character class' => sub {
    $r->regex('[\\p{^Digit}]');
    my $vis = $r->visual;
    is($vis, '[\\P{Digit}]', '\\p{^Digit} in char class normalizes to \\P{Digit}');

    my @nodes = @{ $r->root };
    is($nodes[0]->family, 'anyof', 'outer node is anyof');
    # Inspect the data array for the anyof_class containing the prop
    my @data = @{ $nodes[0]->{data} };
    my $found_neg_prop = 0;
    for my $child (@data) {
        if ($child->isa('Regexp::Parser::anyof_class')) {
            my $inner = $child->{data};
            if ($inner->isa('Regexp::Parser::prop')) {
                is($inner->neg, 1, 'prop neg flag set in character class');
                is($inner->type, 'Digit', 'prop type is Digit');
                $found_neg_prop = 1;
            }
        }
    }
    ok($found_neg_prop, 'found negated prop inside character class');
};

subtest '\\p{^Name} round-trip' => sub {
    # After normalization, \p{^Greek} becomes \P{Greek}
    # Round-trip: \P{Greek} -> \P{Greek}
    $r->regex('\\P{Greek}');
    my $vis1 = $r->visual;
    $r->regex($vis1);
    my $vis2 = $r->visual;
    is($vis2, $vis1, 'round-trip \\P{Greek}');
};

done_testing;
