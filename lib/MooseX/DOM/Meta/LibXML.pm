# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/Meta/LibXML.pm 89522 2008-10-28T01:36:10.445014Z daisuke  $

package MooseX::DOM::Meta::LibXML;
use Moose::Role;
use MooseX::DOM::LibXML;

with 'MooseX::DOM::Meta::Class';

around 'reinitialize' => sub {
    my ($next, @args) = @_;
    my $meta = $next->(@args);
    $meta->backend( MooseX::DOM::LibXML->instance );
    $meta->backend->setup( $meta );
    return $meta;
};

no Moose::Role;

1;

__END__

=head1 NAME

MooseX::DOM::Meta::LibXML - Meta Class With LibXML Backend

=cut
