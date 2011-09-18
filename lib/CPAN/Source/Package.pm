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
#    isa => 'CPAN::Source::Dist';


sub fetch_pm { 
    my $self = shift;
    my $path = $self->class;
    $path =~ s{::}{/}g;
    $path = 'lib/' . $path . '.pm';
    return $self->dist->fetch_source_file( $path );
}

sub data { 
    my $self = shift;
    my @attrs = $self->meta->get_all_attributes;
    my $data = {  };
    for my $attr ( @attrs ) {
        next if $attr->name =~ /^_/; # skip private attribute
        $data->{ $attr->name } = $attr->get_value( $self );
    }
    return $data;
}

1;
