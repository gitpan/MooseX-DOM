# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/t/lib/Test/MooseX/DOM/Recipe001.pm 88873 2008-10-23T15:34:02.795690Z daisuke  $

package Test::MooseX::DOM::Recipe001;
use Moose;
use MooseX::DOM;

dom_nodes 'foo';
dom_nodes 'bar';
dom_value '@attr';

no Moose;
no MooseX::DOM;

1;
