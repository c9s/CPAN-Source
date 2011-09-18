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


sub fetch_source_file { 
    my ($self,$file) = @_;
    return unless $self->source_path;
    my $uri = URI->new( $self->source_path . '/' . $file );
    return $self->_parent->http_get( $uri );
}

sub fetch_meta { 
    my $self = shift;
    my $yaml = $self->fetch_source_file( 'META.yml' );
    return YAML::XS::Load( $yaml );
}

sub fetch_readme { 
    my $self = shift;
    return $self->fetch_source_file( 'README' );
}

sub fetch_changes {
    my $self = shift;
    return $self->fetch_source_file( 'Changes' )
        || $self->fetch_source_file( 'Changelog' );
        || $self->fetch_source_file( 'CHANGELOG' );
}

sub fetch_todo {
    my $self = shift;
    return $self->fetch_source_file( 'TODO' )
      || $self->fetch_source_file( 'Todo' );
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
