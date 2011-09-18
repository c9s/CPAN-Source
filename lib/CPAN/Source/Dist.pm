package CPAN::Source::Dist;
use warnings;
use strict;
use Any::Moose;
use JSON::XS;
use overload '""' => \&to_string;

has dist => is => 'rw', isa => 'Str';
has distvname => is => 'rw';
has version => is => 'rw', isa => 'Str';
has maturity => is => 'rw';
has filename => is => 'rw';
has cpanid => is => 'rw';
has extension => is => 'rw';
has pathname => is => 'rw';

sub BUILD {
    my $self = shift;
}

sub to_string { 
    my $self = shift;
    my @attrs = $self->meta->get_all_attributes;
    my $data = {  };
    for my $attr ( @attrs ) {
        $data->{ $attr->name } = $attr->get_value( $self );
    }
    return encode_json( $data );
}

1;
