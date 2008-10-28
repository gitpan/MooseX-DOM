use strict;
use lib "t/lib";
use Test::More (tests => 5);

BEGIN
{
    use_ok( "Test::MooseX::DOM::Recipe002" );
}

my $obj = Test::MooseX::DOM::Recipe002->parse_string(<<EOXML);
<?xml version="1.0"?>
<root>
    <foo>1</foo>
    <foo>2</foo>
    <foo>3</foo>
</root>
EOXML

my @foo = $obj->foo;
is( scalar @foo, 3, "\@foo count ok" );

for(1..3) {
    is($foo[$_ - 1]->value, $_, "foo value ok");
}
