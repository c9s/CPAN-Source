package CPAN::Source::Package;
use warnings;
use strict;
use Any::Moose;

has class =>
    is => 'rw',
    isa => 'Str';

has version =>
    is => 'rw',
    isa => 'Str';

has path =>
    is => 'rw',
    isa => 'Str';

has dist => 
    is => 'rw';



1;
