# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/LibXML.pm 68159 2008-08-10T23:52:30.531394Z daisuke  $

package MooseX::DOM::LibXML;
use Moose::Role;
use MooseX::DOM::LibXML::ContextNode;

use constant DEFAULT_NAMESPACE_PREFIX => "#default";

has 'node' => (
    is => 'rw',
    isa => 'MooseX::DOM::LibXML::ContextNode',
);

has 'namespaces' => (
    is => 'rw',
    isa => 'HashRef',
    required => 1,
    default => sub { +{} }
);

no Moose;

sub BUILDARGS {
    my ($self, %args) = @_;

    my $namespaces = $args{namespaces} || {};
    my $node = delete $args{node};
    if ($node) {
        if (! ref $node) {
            $node = MooseX::DOM::LibXML::ContextNode->new(
                node => XML::LibXML->new->parse_string($node)->documentElement,
                namespaces => $namespaces
            );
        } elsif ($node->isa('XML::LibXML::Element')) {
            $node = MooseX::DOM::LibXML::ContextNode->new(
                node => $node,
                namespaces => $namespaces
            );
        } else {
            confess "Don't know how to handle $node";
        }

        $args{node} = $node;
    }

    return  { %args };
}

BOOTSTRAP: {
    my $subname = sub { join('::', $_[1] || __PACKAGE__, $_[0]) };
    my $subassign = sub {
        no strict 'refs';
        *{$_[0]} = Class::MOP::subname($_[0], $_[1]);
    };

    # Used to convert element node to its text content
    my $textfilter = sub {
        my $self = shift;
        return map { blessed $_ && $_->can('textContent') ? $_->textContent : $_ } @_;
    };

    # Used only in has_dom_child, to create an element node from a text
    my $text2element = Class::MOP::subname($subname->('text2element') => sub {
        my ($self, %args) = @_;

        my $child = $args{child};
        my $value = $args{value};
        my $namespace = $args{namespace};
        my $tag = $args{tag};
        my $node = $self->node;

        my $nsuri = $self->namespaces->{ $namespace };
        if (! $child) {
            my $document = $node->ownerDocument;
            $child = ($nsuri) ?
                $document->createElementNS($nsuri, $tag) :
                $document->createElement($tag)
            ;
            $node->appendChild($child);
        }

        $child->removeChildNodes();
        $child->appendTextNode($value);
    });

    # Used only in has_dom_children, to create a list of element nodes from
    # list of text
    my $text2elements = Class::MOP::subname($subname->('text2elements') => sub {
        my($self, %args) = @_;

        my $children = $args{children};
        my $values = $args{values};
        my $namespace = $args{namespace};
        my $tag = $args{tag};

        my $node = $self->node;

        if ($children) {
            $node->removeChild($_) for @$children;
        }
        my $nsuri = $self->namespaces->{ $namespace };
        my $document = $node->ownerDocument;
        my @children;
        foreach my $data (@$values) {
            my $child = ($nsuri) ?
                $document->createElementNS($nsuri, $tag) :
                $document->createElement($tag)
            ;
            $child->appendTextNode($data);
            push @children, $child;
            $node->appendChild($child);
        }
    });

    my %exports = (
        has_dom_root => sub {
            return Class::MOP::subname($subname->('has_dom_root') => sub ($;%) {
                my $caller = caller();
                my ($tag, %args) = @_;
                # tag => $tag
                # attributes => { attr1 => $val1, attr2 => $val2 }

                $tag = $args{tag} if $args{tag};
                my $attrs = $args{attributes};

                my $meta = $caller->meta;
                $meta->{'$!dom_root'} = { tag => $tag, attributes => $attrs };

                my $assert_root = sub {
                    my $self = shift;
                    my $node = shift || $self->node;
                    if ($node && $node->getName ne $tag) {
                        confess "given node does not have required root node $tag";
                    }
                };

                $meta->add_around_method_modifier(new => sub {
                    my $next = shift;
                    my $self = $next->(@_);
                    $assert_root->($self);
                    return $self;
                });
                $meta->add_after_method_modifier(node => sub {
                    my $self = shift;
                    if (@_) {
                        $assert_root->($self, @_);
                    }
                });
            });
        },
        has_dom_content => sub {
            return Class::MOP::subname($subname->('has_dom_content') => sub ($) {
                my $caller = caller();
                my $name = shift;
                my $method = $subname->($name, $caller);
                $subassign->($method => sub {
                    my $self = shift;
                    my $node = $self->node;
                    return () unless $node;

                    if (@_) {
                        $node->removeChildNodes();
                        $node->appendText($_[0]);
                    }

                    return $node->textContent;
                } );
            });
        },
        has_dom_attr => sub {
            return Class::MOP::subname($subname->('has_dom_attr') => sub ($;%) {
                my $caller = caller();
                my ($name, %args) = @_;

                if ($args{accessor}) {
                    $name = $args{accessor};
                }

                $caller->meta->{'%!dom_attributes'}->{$name} = 1;
                my $method = $subname->($name, $caller);
                $subassign->($method => sub {
                    my $self = shift;
                    my $node = $self->node;
                    return () unless $node;

                    if (@_) {
                        $node->setAttribute($name, $_[0]);
                    }

                    return $node->getAttribute($name);
                });
            });
        },
        has_dom_children => sub {
            return Class::MOP::subname($subname->('has_dom_children') => sub ($;%) {
                my $caller = caller();
                my($name, %args) = @_;
                my $namespace = $args{namespace} ||= DEFAULT_NAMESPACE_PREFIX;
                my $tagname   = $args{tag} || $name;
                my $filter    = $args{filter} || $textfilter;
                my $create    = $args{create} || $text2elements;
                if ($args{accessor}) {
                    $name = $args{accessor};
                }
                $caller->meta->{'%!dom_attributes'}->{$name} = 1;
                my $method = $subname->($name, $caller);

                # list accessor
                $subassign->($method => sub {
                    my $self = shift;
                    my $node = $self->node;
                    my $nsuri = $self->namespaces->{ $namespace };
                    my @children = ($nsuri) ?
                        $node->getChildrenByTagNameNS($nsuri, $tagname):
                        $node->getChildrenByTagName($tagname)
                    ;
                    if (@_) {
                        $create->($self, children => \@children, values => \@_, namespace => $namespace, tag => $tagname);
                    }

                    return $filter->($self, @children);
                });
            });
        },
        has_dom_child => sub {
            return Class::MOP::subname($subname->('has_dom_child') => sub ($;%) {
                my $caller = caller();
                my ($name, %args) = @_;

                my $namespace = $args{namespace} ||= DEFAULT_NAMESPACE_PREFIX;
                my $tagname   = $args{tag} || $name;
                my $filter    = $args{filter} || $textfilter;
                my $create    = $args{create} || $text2element;
                if ($args{accessor}) {
                    $name = $args{accessor};
                }

                my $meta = $caller->meta;
                $meta->{'%!dom_attributes'}->{$name} = 1;
                my $method = $subname->($name, $caller);
                $subassign->($method => sub {
                    my $self = shift;

                    my $node = $self->node;
                    my $child;
                    if ($node) {
                        my $nsuri = $self->namespaces->{ $namespace };
                        ($child) = ($nsuri) ?
                            $node->getChildrenByTagNameNS($nsuri, $tagname):
                            $node->getChildrenByTagName($tagname)
                        ;
                    }

                    if (@_) {
                        $self->__create_root_node();
                        $create->( $self, child => $child, value => $_[0], namespace => $namespace, tag => $tagname);
                    }

                    my($ret) = $filter->( $self, $child );
                    return $ret;
                });
            });
        }
    );

    my $export = Sub::Exporter::build_exporter({
        exports => \%exports,
        groups  => { default => [ ':all' ] }
    });
    sub export_dsl {
        goto &$export if $export;
    }

    sub unexport_dsl {
        no strict 'refs';
        my $class = caller();

        # loop through the exports ...
        foreach my $name ( keys %exports ) {

            # if we find one ...
            if ( defined &{ $class . '::' . $name } ) {
                my $keyword = \&{ $class . '::' . $name };

                # make sure it is from Moose
                my ($pkg_name) = Class::MOP::get_code_info($keyword);
                next if $pkg_name ne __PACKAGE__;

                # and if it is from Moose then undef the slot
                delete ${ $class . '::' }{$name};
            }
        }
    }
}

sub BUILD {
    my ($self, $args) = @_;

    if (my $attrs = $self->meta->{'%!dom_attributes'}) {
        foreach my $attr (keys %$attrs) {
            next unless defined $args->{$attr};
            $self->$attr( $args->{ $attr } );
        }
    }
    return $self;
}

sub from_xml {
    my $class = shift;
    return $class->new(node => XML::LibXML->new->parse_string($_[0])->documentElement);
}
sub from_file {
    my $class = shift;
    return $class->new(node => XML::LibXML->new->parse_file($_[0])->documentElement);
}

sub as_xml {
    my $self = shift;
    $self->node->toString(1);
}

sub __create_root_node {
    my $self = shift;
    return if $self->node;

    my $root = $self->meta->{'$!dom_root'};
    confess "No root node defined" unless $root;

    my $tag = $root->{tag};
    my $attrs = $root->{attributes};
    my $doc = XML::LibXML::Document->new( '1.0' => 'UTF-8' );
    my $node = $doc->createElement($tag);
    while (my($name, $value) = each %$attrs) {
        $node->setAttribute($name, $value);
    }
    $self->node( MooseX::DOM::LibXML::ContextNode->new(node => $node) );
}


1;

