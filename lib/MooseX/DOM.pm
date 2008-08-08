# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM.pm 68056 2008-08-08T07:06:00.411817Z daisuke  $

package MooseX::DOM;
use strict;
use Moose::Util;

our $AUTHORITY = 'cpan:DMAKI';
our $VERSION   = '0.00001';

sub import {
    my ($class, %args) = @_;

    my $caller = caller(0);
    return unless $caller->can('meta');

    $args{engine} ||= 'LibXML';
    my $engine = $args{engine};
    if ($engine !~ s/^\+//) {
        $engine = join('::', __PACKAGE__, $engine);
    }

    Moose::Util::apply_all_roles($caller->meta, $engine);

    my $exporter = join('::', $engine, 'export_dsl');
    goto &$exporter;
}

1;

__END__

=head1 NAME

MooseX::DOM - Simplistic Object XML Mapper

=head1 SYNOPSIS

  package MyObject;
  use Moose;
  use MooseX::DOM;
 
  has_dom_child 'title';

  no Moose;

  my $obj = MyObject->new(node => <<EOXML);
  <feed>
    <title>Foo</title>
  </feed>
  EOXML

  print $obj->title(), "\n"; # Foo
  $obj->title('Bar');
  print $obj->title(), "\n"; # Bar

=head1 DESCRIPTION

This module is intended to be used in conjunction with other modules
that encapsulate XML data (for example, XML feeds).

=head1 DECLARATION

=head2 has_dom_attr $name[, %opts]

Specifies that the object should contain an attribute by the given name

=head2 has_dom_child $name[, %opts]

Specifies that the object should contain a single child by the given name.
Will generate accessor that can handle set/get

  has_dom_child 'foo';

  $obj->foo(); # get the value of child element foo
  $obj->foo("bar"); # set the value of child element foo to bar

%opts may contain C<namespace>, C<tag>, and C<filter>

Specifying C<namespace> forces MooseX::DOM to look for tags in a specific
namespace uri.

Specifying C<tag> allows MooseX::DOM to look for the tag name given in C<tag>
while making the generated method name as C<$name>

The optional C<filter> should be a subroutine that takes the object itself
as the first parameter, and the DOM node(s) as the rest of the parameters.
You are allowed to transform the node as you like. By default, a filter
that converts the node to its text content is used.

=head2 has_dom_children 

Specifies that the object should contain possibly multiple children by the
given name

  has_dom_children 'foo';

  $obj->foo(); # Returns a list of values for each child element foo
  $obj->foo(qw(1 2 3)); # Discards old values of foo, and create new nodes

%opts may contain C<namespace>, C<tag>, and C<filter>

Specifying C<namespace> forces MooseX::DOM to look for tags in a specific
namespace uri.

Specifying C<tag> allows MooseX::DOM to look for the tag name given in C<tag>
while making the generated method name as C<$name>

The optional C<filter> should be a subroutine that takes the object itself
as the first parameter, and the DOM node(s) as the rest of the parameters.
You are allowed to transform the node as you like. By default, a filter
that converts the node to its text content is used.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut