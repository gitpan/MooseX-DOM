use strict;
use lib "t/lib";
use Test::More (tests => 5);

BEGIN
{
    use_ok( "Test::MooseX::DOM::Recipe001" );
}

my $obj = Test::MooseX::DOM::Recipe001->parse_string(<<EOXML);
<?xml version="1.0"?>
<root attr="attr_value">
    <foo>1</foo>
    <bar>2</bar>
</root>
EOXML

can_ok( $obj, qw(attr foo bar) );
is( $obj->attr, 'attr_value', 'attr ok');
is( $obj->foo,  '1', 'foo ok' );
is( $obj->bar,  '2', 'bar ok' );