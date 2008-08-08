# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/LibXML.pm 68055 2008-08-08T06:52:10.128282Z daisuke  $

package MooseX::DOM::LibXML;
use Moose::Role;
use MooseX::DOM::LibXML::ContextNode;

use constant DEFAULT_NAMESPACE_PREFIX => "#default";

has 'node' => (
    is => 'rw',
    isa => 'MooseX::DOM::LibXML::ContextNode',
    required => 1,
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
        } elsif ($node->isa('XML::LibxML::Element')) {
            $node = MooseX::DOM::LibXML::ContextNode->new(
                node => $node,
                namespaces => $namespaces
            );
        } else {
            confess "Don't know how to handle $node";
        }
    }

    return  { %args, node => $node };
}

{
    my $textfilter = sub {
        my $self = shift;
        return map { $_->textContent } @_;
    };
    my $subname = sub { join('::', $_[1] || __PACKAGE__, $_[0]) };
    my $subassign = sub {
        no strict 'refs';
        *{$_[0]} = Class::MOP::subname($_[0], $_[1]);
    };

    my $CALLER;

    my %exports = (
        has_dom_attr => sub {
            return Class::MOP::subname($subname->('has_dom_attr') => sub ($;%) {
                my $caller = caller();
                my ($name, %args) = @_;

                my $method = $subname->($name, $caller);
                $subassign->($method => sub {
                    my $self = shift;
                    my $node = $self->node;
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
                        $node->removeChild($_) for @children;
                        my $document = $node->ownerDocument;
                        foreach my $data (@_) {
                            my $child = ($nsuri) ?
                                $document->createElementNS($nsuri, $tagname) :
                                $document->createElement($tagname)
                            ;
                            $child->appendTextNode($data);
                            push @children, $child;
                            $node->appendChild($child);
                        }
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

                my $method = $subname->($name, $caller);
                $subassign->($method => sub {
                    my $self = shift;

                    my $node = $self->node;
                    my $nsuri = $self->namespaces->{ $namespace };
                    my ($child) = ($nsuri) ?
                        $node->getChildrenByTagNameNS($nsuri, $tagname):
                        $node->getChildrenByTagName($tagname)
                    ;

            
                    if (@_) {
                        if (! $child) {
                            my $document = $node->ownerDocument;
                            $child = ($nsuri) ?
                                $document->createElementNS($nsuri, $tagname) :
                                $document->createElement($tagname)
                            ;
                            $node->appendChild($child);
                        }
                        $child->removeChildNodes();
                        $child->appendTextNode($_[0]);
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
        goto &$export;
    }
}

sub as_xml {
    my $self = shift;
    $self->node->toString(1);
}

1;

