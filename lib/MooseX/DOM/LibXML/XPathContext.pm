# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/LibXML/XPathContext.pm 88873 2008-10-23T15:34:02.795690Z daisuke  $

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
    handles => [ qw(findnodes findvalue) ]
);          
        
__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub BUILDARGS {
    my $class = shift;
    my %args  = scalar(@_) == 1 ? (node => $_[0]) : @_;
    return \%args;
}

1;
