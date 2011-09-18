#!/usr/bin/env perl
use lib 'lib';
use CPAN::Source;
use Test::More 'no_plan';

my $source = CPAN::Source->new( 
    mirror => 'http://cpan.nctu.edu.tw',
    cache_path => '.cache' , 
    cache_expiry => '14 days' );

my $pkg_data;
ok( $source );
ok( $pkg_data = $source->prepare_package_data );

my $dist = $source->dist('Moose');

ok( $dist );

while( my ($k,$v) = each %{ $source->dists } ) { 
    ok( $k );
    ok( $v );
    ok( $v->name );
    ok( $v->version );
    ok( $v->cpanid );
}


my ($pkg_name,$pkg) = each %{ $source->package_data };
ok( $pkg_name , $pkg_name );
ok( $pkg );
my $pm_content = $pkg->fetch_pm;
ok( $pm_content );
warn $pm_content;
