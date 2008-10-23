# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM.pm 88873 2008-10-23T15:34:02.795690Z daisuke  $

package MooseX::DOM;
use strict;
use warnings;
use 5.008;
use MooseX::DOM::Meta::Class;

our $AUTHORITY = 'cpan:DMAKI';
our $VERSION   = '0.00999';

sub import {
    my $class = shift;
    my $caller = caller();

    my $backend = 'MooseX::DOM::LibXML';
    Class::MOP::load_class($backend);

    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class => $caller,
        metaclass_roles => [ 'MooseX::DOM::Meta::Class' ]
    );
    $backend->setup($caller);
    $class->export_keywords($caller);
}

sub unimport {
    my $class = shift;
    my $caller = caller();

    $class->unexport_keywords($caller);
}

sub export_keywords {
    my ($class, $caller) = @_;

    my $exporter = Sub::Exporter::build_exporter({
        into => $caller,
        groups => { default => [ ':all' ] },
        exports => [
            dom_nodes      => sub { $class->build_dom_nodes($caller) },
            dom_fetchnodes => sub { $class->build_dom_fetchnodes($caller) },
            dom_to_class   => sub { $class->build_dom_to_class($caller) },
            dom_value      => sub { $class->build_dom_value($caller) },
        ]
    });
    $exporter->($class);
}

sub unexport_keywords {
    my ($class, $caller) = @_;
    my @keywords = qw(dom_nodes dom_fetchnodes dom_to_class dom_value);

    { no strict 'refs';
        foreach my $name (@keywords) {
            if ( defined &{ $caller . '::' . $name }) {
                delete ${ $caller . '::' }{$name};
            }
        }
    }
}

sub build_dom_value {
    my ($class, $caller) = @_;

    return sub {
        my $name = shift;
        my $args = { @_ == 1 ? (fetch => {xpath => $_[0]}) : @_ };

        my $fetch = $args->{fetch};
        my $fetch_xpath = $fetch->{xpath} || $name;
        my $meta = $caller->meta;
        $meta->add_method(
            $name,
            Moose::Meta::Method->wrap(
                package_name => $caller,
                name         => $name,
                body         => sub {
                    my $self = shift;
                    $self->dom_root->findvalue($fetch_xpath);
                }
            )
        );
    };
}

sub build_dom_nodes {
    my ($class, $caller) = @_;

    return sub {
        my $name = shift;
        my $args = { @_ == 1 ? (fetch => $_[0]) : @_ };

        $args->{into} = $caller;
        my @methods = (
            $class->build_dom_nodes_accessor($name, $args),
            $class->build_dom_nodes_appender($name, $args),
        );

        my $meta = $caller->meta;
        foreach my $method (@methods) {
            $meta->add_method($method->{name}, $method->{code});
        }
    }
}

sub build_dom_nodes_appender {
    my ($class, $name, $args) = @_;

    # I can't figure out this one automatically (I think). 
    # just expect a code, and if I can't find it, not methods are
    # returned to the callee
    my $config = ref $args->{append} eq 'HASH' ? $args->{append} : 
        { code => $args->{append} };
    my $method = $config->{name} || "add_$name";
    my $code = $config->{code};
    my $ret;
    if ($code) {
        $ret = {
            $method,
            Moose::Meta::Method->wrap(
                package_name => $args->{into},
                name         => $method,
                body         => $code
            )
        };
    }
    return $ret ? $ret : ();
}

sub build_dom_nodes_accessor {
    my ($class, $name, $args) = @_;

    my $fetch = $args->{fetch};
    my $store = $args->{store};

    if (! ref $fetch) {
        my $xpath = $fetch;
        $fetch = sub { shift->dom_root->findnodes($xpath) };
    }

    my $code = <<"    EOSUB";
        sub {
            my \$self = shift;
            my \@ret = \$fetch->(\$self);
    EOSUB
    if ($store) {
        $code .= <<"        EOSUB";
            if (\@_) {
                \$store->(\$self, \@_);
            }
        EOSUB
    }

    $code .= <<"    EOSUB";
            return \@ret;
        }
    EOSUB
    my $cv = eval $code; Carp::confess($@) if $@;

    return {
        name => $name,
        code => Moose::Meta::Method->wrap(
            package_name => $args->{into},
            name         => $name,
            body         => $cv,
        )
    };
}

sub build_dom_fetchnodes {
    my ($class, $caller) = @_;

    return sub {
        my $args = {@_ == 1 ? (xpath => $_[0]) : @_};
        my $filter = $args->{filter};
        my $xpath  = $args->{xpath};
        return $filter ?
            sub {
                my $self = shift;
                return $filter->($self->dom_root->findnodes($xpath));
            } :
            sub {
                my $self = shift;
                return $self->dom_root->findnodes($xpath);
            }
    };
}

sub build_dom_to_class {
    my ($class, $caller) = @_;

    return sub {
        my $args = {@_ == 1 ? (to_class => $_[0]) : @_};
        my $to_class = $args->{to_class};
        Class::MOP::load_class($to_class);
        return sub {
            map { $to_class->new($_) } @_;
        }
    }
}
1;

__END__

=head1 NAME

MooseX::DOM - Easily Create DOM Based Objects

=head1 SYNOPSIS

    package RSS;
    use Moose;
    use MooseX::DOM;

    dom_value 'version' => '@version';
    dom_nodes 'items' => (
        fetch => dom_fetchnodes(
            xpath => 'channel/item',
            filter => dom_to_class('RSS::Item')
        )
    );

    # or, easy way (just get some DOM nodes)
    # dom_nodes 'items' => 'channel/items';

    # or, create your own way to fetch the nodes
    # dom_nodes 'items' => (
    #     fetch => sub { ... }
    # );

    no Moose;
    no MooseX::DOM;

    package RSS::Item;
    use Moose;
    use MooseX::DOM;

    dom_value 'title';
    dom_value 'description';
    dom_value 'link';

    no Moose;
    no MooseX::DOM;

    sub BUILDARGS {
        my $class = shift;
        my $args  = {@_ == 1? (dom_root => $_[0]) : @_};
        return $args;
    }

    package main;

    # parse_file() is automatically created for you.
    my $rss = RSS->parse_file('rss.xml');
    foreach my $item ($rss->items) {
        print "item link  = ", $item->link, "\n";
        print "item title = ", $item->title, "\n";
    }

=head1 DESCRIPTION

MooseX::DOM is a tool that allows you to define classes that are based on
XML DOM.

=head1 PROVIDED DSL

The following DSL is provided upon calling C<MooseX::DOM>. When 
C<no MooseX::DOM> is used, these functions are removed from your namespace.

=head2 dom_nodes $name => %spec

Declares that a method named $name should be built, using the given spec.
Returns a list of nodes, or what the filter argument trasnlates them to.

If %spec is omitted, $name is taken to be the xpath to fetch.

=head2 dom_value $name => %spec

Declares that a method named $name should be built, using the given spec.
Returns the result of the fetch, whatever that may be.

If %spec is omitted, $name is taken to be the xpath to fetch.

=head2 dom_fetchnodes %spec

Creates a closure that fetches some nodes

=head2 dom_to_class %spec

Creates a closure that transforms nodes to something else, typically an object.

=head1 PROVIDED METHODS

The following methods are built onto your class automatically.

=head2 parse_file

=head2 parse_string

=head2 parse_fh

These methods allow you to parse a piece of XML, and build a MooseX::DOM
object based on it.

=head2 dom_findnodes($xpath)

Does a DOM XPath lookup. Returns a plain DOM object.

=head2 dom_findvalue($xpath)

Does a DOM XPath lookup. Returns whatever value the XPath results to.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut