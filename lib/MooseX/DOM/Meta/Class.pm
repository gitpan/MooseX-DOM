# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/Meta/Class.pm 88873 2008-10-23T15:34:02.795690Z daisuke  $

package MooseX::DOM::Meta::Class;
use Moose::Role;

has 'backend' => (
    is => 'rw',
);

no Moose::Role;

1;
