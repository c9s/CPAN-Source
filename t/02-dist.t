#!/usr/bin/env perl
use Test::More tests => 3;
use CPAN::Source::Dist;

my $dist = CPAN::Source::Dist->new( dist => 'Test' , version => '0.01' );
ok( $dist );
ok( $dist->to_string );
ok( $dist . '' );

;
