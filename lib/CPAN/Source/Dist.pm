package CPAN::Source::Dist;
use warnings;
use strict;
use base qw(Class::Accessor::Fast::XS);
__PACKAGE__->mk_accessors(qw(
    name 
    version_name 
    version 
    maturity 
    filename 
    cpanid 
    extension 
    pathname
    source_path 
    _parent
));
use JSON::XS;
use YAML::XS;
use URI;
use overload '""' => \&to_string;

# use Mouse;
# has name => is => 'rw', isa => 'Str';
# 
# has version_name => is => 'rw';
# 
# has version => is => 'rw', isa => 'Str';
# 
# has maturity => is => 'rw';
# 
# has filename => is => 'rw';
# 
# has cpanid => is => 'rw';
# 
# has extension => is => 'rw';
# 
# has pathname => is => 'rw';
# 
# has source_path => is => 'rw';
# 
# has _parent => is => 'rw', isa => 'CPAN::Source';

# CPAN::DistnameInfo compatible
sub dist { $_[0]->name; }

sub distvname { $_[0]->version_name; }

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
            || $self->fetch_source_file( 'Changelog' )
            || $self->fetch_source_file( 'CHANGELOG' );
}

sub fetch_todo {
    my $self = shift;
    return $self->fetch_source_file( 'TODO' )
        || $self->fetch_source_file( 'Todo' );
}

sub fetch_tarball {
    # TODO:
}

sub data { 
    my $self = shift;
    return {
        name  => $self->name,
        version_name  => $self->version_name,
        version => $self->version,
        maturity  => $self->maturity,
        filename  => $self->filename,
        cpanid    => $self->cpanid,
        extension => $self->extension,
        pathname  => $self->pathname,
        source_path => $self->source_path,
    };
}

sub to_string { 
    my $self = shift;
    my $data = $self->data();
    return encode_json( $data );
}

1;
