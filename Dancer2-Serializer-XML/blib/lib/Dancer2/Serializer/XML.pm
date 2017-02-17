package Dancer2::Serializer::XML;
#ABSTRACT: serializer for handling XML data
our $AUTHORITY = 'cpan:IGIBBS';
use strict;
use warnings;
use Carp;
use Moo;
use Dancer2;	# So that setting is available in tests
use Data::Dumper;
use Class::Load 'load_class';
with 'Dancer2::Core::Role::Serializer';

our $VERSION = '0.01';

has '+content_type' => ( default => sub {'application/xml'} );

sub BUILD
{
    my ($self) = @_;
    die 'XML::Simple is needed and is not installed' unless $self->loaded_xmlsimple;
    die 'XML::Simple needs XML::Parser or XML::SAX and neither is installed' unless $self->loaded_xmlbackends;
}

sub serialize
{
	my $self    = shift;
	my $entity  = shift;
	my %options = (RootName => 'data');

	my $s = setting('engines') || {};
	if(exists($s->{serializer}) && exists($s->{serializer}{serialize}))
	{
		%options = (%options, %{$s->{serializer}{serialize}});
	}

	my $xml = XML::Simple::XMLout($entity, %options);
	utf8::encode($xml);
	return $xml;
}

sub deserialize
{
	my $self = shift;
	my $xml = shift;
	my %options = ();
	
	utf8::decode($xml);

	my $s = setting('engines') || {};
	if(exists($s->{serializer}) && exists($s->{serializer}{deserialize}))
	{
		%options = (%options, %{$s->{serializer}{deserialize}});
	}

	return XML::Simple::XMLin($xml, %options);
}

sub loaded_xmlsimple {
	load_class('XML::Simple');
}

sub loaded_xmlbackends {
    # we need either XML::Parser or XML::SAX too
    load_class('XML::Parser') or
    load_class('XML::SAX');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Serializer::XML - serializer for handling XML data

=head1 VERSION

version 0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=head2 serialize

Serialize a data structure to an XML structure.

=head2 deserialize

Deserialize an XML structure to a data structure

=head2 content_type

Return 'text/xml'

=head2 CONFIG FILE

You can set XML::Simple options for serialize and deserialize in the
config file. The default behaviour is for no options to be passed to
XML:: Simple, thus retaining XML::Simple default behaviour and backwards
compatibility with Dancer::Serializer::XML. 

For new code, these are the recommended settings for consistent 
behaviour:

   engines:
      XMLSerializer:
        serialize:
           AttrIndent: 1
           KeyAttr: 1
        deserialize:
           ForceArray: 1
           KeyAttr: 1
           ForceContent: 1
           KeepRoot: 1

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ian Gibbs, E<lt>igibbs@cpan.orgE<gt> and
Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Ian Gibbs and
Copyright (C) 2010 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
