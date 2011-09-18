use inc::Module::Install;
name 'CPAN-Source';

perl_version '5.10';
all_from 'lib/CPAN/Source.pm';

requires 'Try::Tiny';
requires $_ for qw(URI Moose Compress::Zlib LWP::UserAgent XML::Simple Cache::File DateTime::Format::HTTP YAML CPAN::DistnameInfo);

tests 't/*.t';
# author_tests 'xt';
# test_requires 'Test::More';
# auto_set_repository;
auto_include;
WriteAll;
