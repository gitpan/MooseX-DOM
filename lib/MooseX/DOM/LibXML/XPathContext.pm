# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/LibXML/XPathContext.pm 89522 2008-10-28T01:36:10.445014Z daisuke  $

package MooseX::DOM::LibXML::XPathContext;
use Moose;
use Moose::Util::TypeConstraints;
use XML::LibXML;
use XML::LibXML::XPathContext;

class_type 'XML::LibXML::Document';
class_type 'XML::LibXML::Element';
coerce 'MooseX::DOM::LibXML::XPathContext'
    => from 'XML::LibXML::Document'
    => via { MooseX::DOM::LibXML::XPathContext->new($_->getDocumentElement) }
;
coerce 'MooseX::DOM::LibXML::XPathContext'
    => from 'XML::LibXML::Element'
    => via { MooseX::DOM::LibXML::XPathContext->new($_) }
;

has 'node' => (
    is => 'rw',
    isa => 'XML::LibXML::Node',
    required => 1,
    trigger  => sub {
        my ($self, $value) = @_;
        $self->xpathcontext(
            XML::LibXML::XPathContext->new($value)
        ); 
    },  
    handles  => [ qw(firstChild textContent toString) ],
);          
            
has 'xpathcontext' => (
    is => 'rw',     
    isa => 'XML::LibXML::XPathContext',
);          
        
__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub BUILDARGS {
    my $class = shift;
    my %args  = scalar(@_) == 1 ? (node => $_[0]) : @_;
    return \%args;
}

sub findnodes {
    my ($self, $xpath) = @_;
    Carp::confess "no xpath specified to findnodes" unless $xpath;
    $self->xpathcontext->findnodes($xpath);
}

sub findvalue {
    my ($self, $xpath) = @_;
    Carp::confess "no xpath specified to findvalue" unless $xpath;
    $self->xpathcontext->findvalue($xpath);
}

1;

__END__

=head1 NAMe

MooseX::DOM::LibXML::XPathContext - Wrapper For DOM Nodes

=head1 METHODS

=head2 findnodes

=head2 findvalue

=cut
