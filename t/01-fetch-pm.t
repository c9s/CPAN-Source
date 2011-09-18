#!/usr/bin/env perl
use lib 'lib';
use CPAN::Source;
use Test::More 'no_plan';

my $source = CPAN::Source->new( 
    mirror => 'http://cpan.nctu.edu.tw',
    cache_path => '.cache' , 
    cache_expiry => '14 days' );

ok( $source->prepare_package_data );

my $dist = $source->dist('Moose');
ok( $dist );


my $pkg = $source->package( 'Moose' );
ok( $pkg );

my $pm_content = $pkg->fetch_pm;
ok( $pm_content );
like( $pm_content , qr/=head1/s );
