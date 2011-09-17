use inc::Module::Install;
name 'CPAN-Source';
all_from 'lib/CPAN/Source.pm';

# requires '';

tests 't/*.t';
# author_tests 'xt';
# test_requires 'Test::More';
# auto_set_repository;
auto_include;
WriteAll;
