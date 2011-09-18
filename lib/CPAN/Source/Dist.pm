package CPAN::Source::Dist;
use warnings;
use strict;
use Any::Moose;
use JSON::XS;
use YAML::XS;
use URI;
use overload '""' => \&to_string;

has dist => is => 'rw', isa => 'Str';
has distvname => is => 'rw';
has version => is => 'rw', isa => 'Str';
has maturity => is => 'rw';
has filename => is => 'rw';
has cpanid => is => 'rw';
has extension => is => 'rw';
has pathname => is => 'rw';
has source_path => is => 'rw';

has _parent => is => 'rw', isa => 'CPAN::Source';

sub BUILD {
    my $self = shift;

}


sub fetch_meta { 
    my $self = shift;
    return unless $self->source_path;
    my $uri = URI->new( $self->source_path . '/' . 'META.yml' );
    my $meta_content = $self->_parent->http_get( $uri );
    return YAML::XS::Load( $meta_content );
}

sub to_string { 
    my $self = shift;
    my @attrs = $self->meta->get_all_attributes;
    my $data = {  };
    for my $attr ( @attrs ) {
        next if $attr->name =~ /^_/; # skip private attribute
        $data->{ $attr->name } = $attr->get_value( $self );
    }
    return encode_json( $data );
}

1;
