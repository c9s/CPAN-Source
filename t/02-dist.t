#!/usr/bin/env perl
use Test::More tests => 6;
use CPAN::Source;
use CPAN::Source::Dist;

my $source = CPAN::Source->new;

my $dist = CPAN::Source::Dist->new( 
    dist => 'Test', 
    version => '0.01', 
    source_path => 'http://cpansearch.perl.org/src/DOY/Moose-2.0205',
    _parent => $source );
ok( $dist );
ok( $dist->to_string );
ok( $dist . '' );

my $meta;
ok( $meta = $dist->fetch_meta );
ok( $meta->{version} );
ok( $meta->{abstract} );

;
