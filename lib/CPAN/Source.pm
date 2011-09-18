package CPAN::Source;
use warnings;
use strict;
use feature qw(say);
use Try::Tiny;
use URI;
use Any::Moose;
use Compress::Zlib;
use LWP::UserAgent;
use XML::Simple qw(XMLin);
use Cache::File;
use DateTime;
use DateTime::Format::HTTP;
use CPAN::DistnameInfo;
use YAML::XS;
use JSON::XS;

use CPAN::Source::Dist;
use CPAN::Source::Package;

use constant { DEBUG => $ENV{DEBUG} };

our $VERSION = '0.01';


# options ...

has cache_path => 
    is => 'rw',
    isa => 'Str';

has cache_expiry => 
    is => 'rw';

has cache =>
    is => 'rw';

has mirror =>
    is => 'rw',
    isa => 'Str';

has source_mirror =>
    is => 'rw',
    isa => 'Str',
    default => sub { 'http://cpansearch.perl.org/' };


# data accessors
has authors => 
    is => 'rw',
    isa => 'HashRef';


# dist info from CPAN::DistnameInfo
has dists =>
    is => 'rw',
    isa => 'HashRef',
    default => sub {  +{  } };

has package_data =>
    is => 'rw',
    isa => 'HashRef';

has modlist => 
    is => 'rw',
    isa => 'HashRef';

has mailrc =>
    is => 'rw',
    isa => 'HashRef';

has stamp => 
    is => 'rw',
    lazy => 1,
    default => sub { 
        my $self = shift;
        my $content = $self->http_get( '/modules/02STAMP' );
        my ( $ts , $date ) = split /\s/,$content;
        return DateTime->from_epoch( epoch => $ts );
    };

has mirrors =>
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    default => sub { 
        my $self = shift;
        return unless $self->mirror;
        # get 07mirror.json
        my $json = $self->http_get( $self->mirror . '/modules/07mirror.json' );
        my $data = decode_json( $json );
        return $data;
    };

sub debug { 
    say "[DEBUG] " ,@_ if DEBUG;
}

sub BUILD {
    my ($self,$args) = @_;
    if( $args->{ cache_path } ) {
        my $cache = Cache::File->new( 
            cache_root => $args->{cache_path},
            default_expires => $args->{cache_expiry} || '3 minutes' );
        $self->cache( $cache );
    }

    $|++ if DEBUG;
}

sub prepare {
    my ($self) = @_;
    $self->prepare_authors;
    $self->prepare_mailrc;
    $self->prepare_package_data;
    $self->prepare_modlist;
}

sub prepare_authors { 
    my $self = shift;

    debug "Prepare authors data...";

    my $xml = $self->http_get( $self->mirror . '/authors/00whois.xml');

    debug "Parsing authors data...";

    my $authors = XMLin( $xml )->{cpanid};
    $self->authors( $authors );
    return $authors;
}

sub prepare_mailrc {
    my $self = shift;
    debug "Prepare mailrc data...";
    my $mailrc_txt = _decode_gzip( $self->http_get( $self->mirror . '/authors/01mailrc.txt.gz') );
    $self->mailrc( $self->parse_mailrc( $mailrc_txt ) );
}

sub prepare_package_data {
    my $self = shift;

    debug "Prepare pacakge data...";

    my $content = _decode_gzip( $self->http_get( $self->mirror . '/modules/02packages.details.txt.gz' ) );

    my @lines = split /\n/,$content;

    # File:         02packages.details.txt
    # URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
    # Description:  Package names found in directory $CPAN/authors/id/
    # Columns:      package name, version, path
    # Intended-For: Automated fetch routines, namespace documentation.
    # Written-By:   PAUSE version 1.14
    # Line-Count:   93553
    # Last-Updated: Thu, 08 Sep 2011 13:38:39 GMT

    my $meta = {  };

    # strip meta tags
    my @meta_lines = splice @lines,0,9;
    for( @meta_lines ) {
        next unless $_;
        my ($attr,$val) = m{^(.*?):\s*(.*?)$};
        $meta->{$attr} = $val;

        debug "meta: $attr => $val ";
    }

    $meta->{'URL'} = URI->new( $meta->{'URL'} );
    $meta->{'Line-Count'} = int( $meta->{'Line-Count'} );
    $meta->{'Last-Updated'} = 
          DateTime::Format::HTTP->parse_datetime( $meta->{'Last-Updated'} );

    my $packages = {  };

    my $cnt = 0;
    my $size = scalar @lines;

    local $|;

    for ( @lines ) {
        my ( $class,$version,$path) = split /\s+/;
        $version = 0 if $version eq 'undef';

        printf("\r [%d/%d] " , ++$cnt , $size) if DEBUG;

        my $tar_path = $self->mirror . '/authors/id/' . $path;

        my $dist;
        my $d = CPAN::DistnameInfo->new( $tar_path );
        if( $d->version ) {
            # register "Foo-Bar" to dists hash...
            $dist = $self->new_dist( $d );
            $self->dists->{ $dist->name } = $dist 
                unless $self->dists->{ $dist->name };
        }

        # Moose::Foo => {  ..... }
        $packages->{ $class } = CPAN::Source::Package->new( 
            class     => $class,
            version   => $version ,
            path      => $tar_path,
            dist      => $dist,
        );

    }

    my $result = { 
        meta => $meta,
        packages => $packages,
    };

    $self->package_data( $result );
    return $result;
}


sub prepare_modlist {
    my $self = shift;

    debug "Prepare modlist data...";
    my $modlist_txt = _decode_gzip( $self->http_get( $self->mirror . '/modules/03modlist.data.gz' ));

    $self->modlist( $self->parse_modlist( $modlist_txt ) );
}


sub fetch_recent {
    my ($self,$period) = @_;
    $period ||= '1d';

    # http://search.cpan.org/CPAN/RECENT-1M.json
    # http://ftp.nara.wide.ad.jp/pub/CPAN/RECENT-1M.json
    return $self->http_get( $self->mirror . '/RECENT-'. $period .'.json' );
}

sub recent {
    my ($self,$period) = @_;
    my $json = $self->fetch_recent( $period );
    return decode_json( $json );
}

sub parse_modlist { 
    my ($self,$modlist_data) = @_;

    debug "Building modlist data ...";

    my @lines = split(/\n/,$modlist_data);
    splice @lines,0,10;
    $modlist_data = join "\n", @lines;
    eval $modlist_data;
    return CPAN::Modulelist->data;
}

sub parse_mailrc { 
    my ($self,$mailrc_txt) = @_;

    debug "Parsing mailrc ...";

    my @lines = split /\n/,$mailrc_txt;
    my %result;
    for ( @lines ) {
        my ($abbr,$name,$email) = ( $_ =~ m{^alias\s+(.*?)\s+"(.*?)\s*<(.*?)>"} );
        $result{ $abbr } = { name => $name , email => $email };
    }
    return \%result;
}

sub module_source_path {
    my ($self,$d) = ($_[0], $_[1]);
    return undef unless $d->distvname;
    return ( $self->source_mirror . '/src/' . $d->cpanid . '/' . $d->distvname );
}


# return dist
sub dist { 
    my ($self,$distname) = @_;
    $distname =~ s/::/-/g;
    return $self->dists->{ $distname };
}

sub http_get { 
    my ($self,$url,$cache_expiry) = @_;

    debug "Downloading $url ...";

    if( $self->cache ) {
        my $c = $self->cache->get( $url );
        return $c if $c;
    }


    my $ua = $self->new_ua;
    my $resp = $ua->get($url);

    $self->cache->set( $url , $resp->content , $cache_expiry ) if $self->cache;
    return $resp->content;
}


sub new_dist {
    my ($self,$d) = @_;
    my $dist = CPAN::Source::Dist->new( 
        $d->properties,
        source_path => $self->module_source_path($d),
        _parent => $self,
    );
    return $dist;
}

sub new_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    return $ua;
}

sub _decode_gzip {
    return Compress::Zlib::memGunzip( $_[0] );
}

1;
__END__
=pod

=head1 NAME

CPAN::Source - CPAN source list data aggregator.

=head1 DESCRIPTION

L<CPAN::Source> fetch, parse, aggregate all CPAN source list for you.

Currently CPAN::Source supports 4 files from CPAN mirror. (00whois.xml,
contains cpan author information, 01mailrc.txt contains author emails, 
02packages.details.txt contains package information, 03modlist contains distribution status)

L<CPAN::Source> aggregate those data, and information can be easily retrieved.

The distribution info is from L<CPAN::DistnameInfo>.

=head1 SYNOPSIS

    my $source = CPAN::Source->new(  
        cache_path => '.cache',
        cache_expiry => '7 days',
        mirror => 'http://cpan.nctu.edu.tw',
        source_mirror => 'http://cpansearch.perl.org'
    );

    $source->prepare;   # use LWP::UserAgent to fetch all source list files ...

    # 00whois.xml
    # 01mailrc
    # 02packages.details.txt
    # 03modlist

    $source->dists;  # all dist information
    $source->authors;  # all author information

    $source->package_data;  # parsed package data from 02packages.details.txt.gz
    $source->modlist;       # parsed package data from 03modlist.data.gz
    $source->mailrc;        # parsed mailrc data  from 01mailrc.txt.gz


    my $dist = $source->dists('Moose');
    my $distname = $dist->name;
    my $distvname = $dist->version_name;
    my $version = $dist->version;  # attributes from CPAN::DistnameInfo
    my $meta_data = $dist->fetch_meta();

    $meta_data->{abstract};
    $meta_data->{version};
    $meta_data->{resources}->{bugtracker};
    $meta_data->{resources}->{repository};

    my $readme = $dist->fetch_readme;
    my $changes = $dist->fetch_changes;

=head1 METHODS

=head2 new( OPTIONS )

=head2 prepare_authors 

=head2 prepare_mailrc

=head2 prepare_modlist

Download 03modlist.data.gz and parse it.

=head2 prepare_package_data

Download 02packages.details.gz and parse it.

=head2 module_source_path

Return full-qualified source path. built from source mirror, the default source mirror is L<http://cpansearch.perl.org>.

=head2 mirrors 

Return mirror info from mirror site. (07mirrors.json)

=head2 dist( $name )

return L<CPAN::Source::Dist> object.

=head2 http_get

Use L<LWP::UserAgent> to fetch content.

=head2 new_dist

Convert L<CPAN::DistnameInfo> into L<CPAN::Source::Dist>.

=head1 ACCESSORS

=for 4

=item package_data

which is a hashref, contains:

    { 
        meta => { 
            File => ...
            URL => ...
            Description => ...
            Line-Count => ...
            Last-Updated => ...
        },
        packages => { 
            'Foo::Bar' => {
                class     => 'Foo::Bar',
                version   =>  0.01 ,
                path      =>  tar path,
                dist      =>  dist name
            }
            ....
        }
    }

=back




=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
