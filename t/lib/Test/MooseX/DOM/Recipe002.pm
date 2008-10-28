# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/t/lib/Test/MooseX/DOM/Recipe002.pm 89519 2008-10-28T01:26:18.906572Z daisuke  $

package Test::MooseX::DOM::Recipe002;
use Moose;
use MooseX::DOM;

dom_nodes 'foo' => (
    fetch => dom_fetchnodes(
        xpath => 'foo',
        filter => dom_to_class('Test::MooseX::DOM::Recipe002::FooItem')
    )
);

no Moose;
no MooseX::DOM;

package Test::MooseX::DOM::Recipe002::FooItem;
use Moose;
use MooseX::DOM qw(BUILDARGS);

dom_value 'value' => '.';

no Moose;
no MooseX::DOM;

1;