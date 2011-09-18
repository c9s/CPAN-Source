package CPAN::Source::Dist;
use warnings;
use strict;
use Any::Moose;

has dist => is => 'rw', isa => 'Str';
has distvname => is => 'rw';
has version => is => 'rw', isa => 'Str';
has maturity => is => 'rw';
has filename => is => 'rw';
has cpanid => is => 'rw';
has extension => is => 'rw';
has pathname => is => 'rw';

1;
