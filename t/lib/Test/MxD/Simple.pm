# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/t/lib/Test/MxD/Simple.pm 68054 2008-08-08T06:49:27.424295Z daisuke  $

package Test::MxD::Simple;
use Moose;
use MooseX::DOM;

has_dom_attr 'attribute';
has_dom_child 'title';
has_dom_children 'multi';

1;