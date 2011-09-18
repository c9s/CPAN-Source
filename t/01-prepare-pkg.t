#!/usr/bin/env perl
use lib 'lib';
use CPAN::Source;
use Test::More tests => 2;

my $source = CPAN::Source->new( 
    mirror => 'http://cpan.nctu.edu.tw',
    cache_path => '.cache' , 
    cache_expiry => '14 days' );

my $pkg_data;
ok( $source );
ok( $pkg_data = $source->prepare_package_data );
