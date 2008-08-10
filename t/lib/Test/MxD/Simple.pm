# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/t/lib/Test/MxD/Simple.pm 68109 2008-08-09T16:04:43.396739Z daisuke  $

package Test::MxD::Simple;
use Moose;
use MooseX::DOM;

has_dom_root 'feed';
has_dom_attr 'attribute';
has_dom_child 'title';
has_dom_children 'multi';

no MooseX::DOM;

1;