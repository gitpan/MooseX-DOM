# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/LibXML.pm 88873 2008-10-23T15:34:02.795690Z daisuke  $

package MooseX::DOM::LibXML;
# I want to use MooseX::Singleton, but it generates some warnings,
# so thi is a plain moose class with package level global
use Moose;
use MooseX::DOM::LibXML::XPathContext;

has 'dom_root_attr' => (
    is => 'rw',
    isa => 'Moose::Meta::Attribute',
    lazy    => 1,
    builder => 'build_dom_root_attr'
);

my @METHODS = qw(parse_file parse_string dom_findvalue dom_findnodes);
foreach my $method (@METHODS) {
    my $attr    = "${method}_method";
    my $builder = "build_${method}_method";

    has $attr=> (
        is => 'rw',
        isa => 'Moose::Meta::Method',
        lazy    => 1,
        builder => $builder
    );
}

__PACKAGE__->meta->make_immutable;
    
no Moose;

our $INSTANCE;

sub setup {
    my ($class, $caller) = @_;

    my $meta = $caller->meta;
    my $self = ($INSTANCE ||= $class->new());
    $self->add_attributes($meta);
    $self->add_methods($meta);
    $meta->backend($self);
}

sub add_attributes {
    my ($self, $meta) = @_;

    $meta->add_attribute( $self->dom_root_attr );
}

sub add_methods {
    my ($self, $meta) = @_;

    foreach my $method (@METHODS) {
        my $attr = "${method}_method";
        $meta->add_method($method => $self->$attr);
    }
}

sub build_dom_root_attr {
    Moose::Meta::Attribute->new(
        dom_root => (
            is     => 'rw',
            isa    => 'MooseX::DOM::LibXML::XPathContext',
            coerce => 1,
        )
    )
}

sub build_parse_file_method {
    my $self = shift;
    return Moose::Meta::Method->wrap(
        package_name => Scalar::Util::blessed $self,
        name         => 'parse_file',
        body         => sub {
            my ($class, $file) = @_;
            $class->new(dom_root =>  XML::LibXML->new->parse_file($file));
        }
    );
}

sub build_parse_string_method {
    my $self = shift;
    return Moose::Meta::Method->wrap(
        package_name => Scalar::Util::blessed $self,
        name         => 'parse_string',
        body         => sub {
            my ($class, $string) = @_;
            $class->new(dom_root =>  XML::LibXML->new->parse_string($string));
        }
    );
}

sub build_dom_findvalue_method {
    my $self = shift;
    return Moose::Meta::Method->wrap(
        package_name => Scalar::Util::blessed $self,
        name         => 'dom_findvalue',
        body         => sub {
            my ($self, $args) = @_;
            if (! ref $args) {
                $args = { xpath => $args };
            }
            $self->dom_root->findvalue($args->{xpath});
        }
    );
}

sub build_dom_findnodes_method {
    my $self = shift;
    return Moose::Meta::Method->wrap(
        package_name => Scalar::Util::blessed $self,
        name         => 'dom_findnodes',
        body         => sub {
            my ($self, $args) = @_;
            if (! ref $args) {
                $args = { xpath => $args };
            }
            $self->dom_root->findnodes($args->{xpath});
        }
    );
}

1;
