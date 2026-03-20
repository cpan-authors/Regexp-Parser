# CLAUDE.md — Regexp::Parser

## What This Is

A Perl module that parses regular expressions into object trees. Originally by Jeff "japhy" Pinyan, now maintained under cpan-authors. Parses Perl regex syntax into traversable node trees for analysis, transformation, or reconstruction.

## Quick Reference

```bash
perl Makefile.PL && make test   # Build and run tests
perl -Ilib t/01simple.t         # Run a single test file
make                            # Build only (copies to blib/)
```

## Architecture

```
lib/Regexp/Parser.pm          # Main parser: regex(), parse(), visual(), walker()
lib/Regexp/Parser/Handlers.pm # 86 handlers registered in init() via add_handler()
lib/Regexp/Parser/Objects.pm  # 31+ node classes, all inherit __object__
lib/Regexp/Parser/Diagnostics.pm # Error constants (RPe_*)
lib/Perl6/Rule/Parser.pm      # Perl 6 rule parser (subclass, mostly historical)
```

**Parser flow**: `regex()` does a two-pass scan (SIZE_ONLY pass then tree-building pass). `parse()` calls `regex()` then `visual()`. Don't call `parse()` after `visual()` — the stack is already consumed.

**Handler pattern**:
```perl
$self->add_handler('sequence' => sub {
    my ($S, $cc) = @_;   # $S = parser, $cc = in-character-class flag
    return $S->object(type => @args);
});
```

**Object pattern**: Each node type is a `{ package Regexp::Parser::name }` block in Objects.pm. Must define `new()`, `visual()`, `type()`, `family()`.

## Conventions

- **Indentation**: 2 spaces in most code, tabs in Makefile.PL
- **Perl version**: `use 5.006` declared, CI tests 5.8+
- **Strict/warnings**: All modules use both
- **Naming**: packages lowercase (`::exact`, `::quant`), methods `snake_case`, constants `UPPER_CASE`, error codes `RPe_*`
- **Lvalue subs**: State accessors (`Rx`, `RxPOS`, `Rf`, `SIZE_ONLY`, `LATEST`) are lvalue subs exported to subclasses
- **Flag bits**: m=0x1, s=0x2, i=0x4, x=0x8, a=0x10, d=0x20, l=0x40, u=0x80, n=0x100

## Testing

- 15 test files in `t/`, 615+ tests total
- All tests use `Test::More`
- Tests cover: basic parsing, subclassing, tree walking, conditionals, captures, character classes, flags, Unicode/POSIX, Perl 5.10+ constructs, recursive patterns, round-trip validation, error rejection

## CI

GitHub Actions: `.github/workflows/{linux,macos,windows}.yml`
- Linux: matrix across Perl 5.8 to latest
- macOS/Windows: latest Perl only
- Env: `PERL_USE_UNSAFE_INC=0`, `AUTOMATED_TESTING=1`

## Known Gaps

Most Perl 5.10+ constructs are now supported. Remaining gaps:
- `(?(DEFINE)...)` definition-only groups
- `(?{ code })` / `(??{ code })` execute correctly at parse time but code blocks are opaque
- Some exotic `(*VERB:arg)` forms with arguments

## Gotchas

- `visual()` triggers `parse()` internally — calling `parse()` then `visual()` is fine, but `visual()` then `parse()` crashes (stack consumed)
- Error checks guarded by `!&SIZE_ONLY` only fire on second pass. `regex()` alone (first pass) won't catch invalid backrefs
- The `ref` object accepts an optional 3rd constructor arg for visual override
- `force_object()` creates nodes during any pass; `object()` only during tree-building pass
- NEXT module is used for dynamic ISA manipulation in `force_object`
