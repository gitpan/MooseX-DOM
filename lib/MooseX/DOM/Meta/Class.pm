# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/Meta/Class.pm 89522 2008-10-28T01:36:10.445014Z daisuke  $

package MooseX::DOM::Meta::Class;
use Moose::Role;

has 'backend' => (
    is => 'rw',
);

no Moose::Role;

1;

__END__

=head1 NAME

MooseX::DOM::Meta::Class - Base Meta Class

=cut
