# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/t/lib/Test/MooseX/DOM/Recipe001.pm 89517 2008-10-28T01:13:13.095376Z daisuke  $

package Test::MooseX::DOM::Recipe001;
use Moose;
use MooseX::DOM;

dom_value 'foo';
dom_value 'bar';
dom_value 'attr' => '@attr';

no Moose;
no MooseX::DOM;

1;
