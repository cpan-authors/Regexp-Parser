use 5.016;
use ExtUtils::MakeMaker;

my $version = MM->parse_version('lib/Regexp/Parser.pm');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Regexp::Parser',
    VERSION_FROM      => 'lib/Regexp/Parser.pm', # finds $VERSION
    MIN_PERL_VERSION  => '5.016',
    LICENSE           => 'perl_5',
    PREREQ_PM         => { 'parent' => 0 },
    TEST_REQUIRES     => { 'Test::More' => 0 },
    ABSTRACT_FROM  => 'lib/Regexp/Parser.pm', # retrieve abstract from module
    AUTHOR         => 'Jeff japhy Pinyan <japhy@perlmonk.org>',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Parser-*' },
    META_MERGE  => {
        'meta-spec' => { version => 2 },
        provides => {
            'Regexp::Parser' => {
                file    => 'lib/Regexp/Parser.pm',
                version => $version,
            },
            'Perl6::Rule::Parser' => {
                file    => 'lib/Perl6/Rule/Parser.pm',
            },
        },
        resources => {
            license    => [ 'https://dev.perl.org/licenses/' ],
            homepage   => 'https://github.com/cpan-authors/Regexp-Parser',
            bugtracker => {
                web => 'https://github.com/cpan-authors/Regexp-Parser/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/Regexp-Parser.git',
                web  => 'https://github.com/cpan-authors/Regexp-Parser',
            },
        },
    },
);
