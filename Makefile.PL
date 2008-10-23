use strict;
use inc::Module::Install;

name('MooseX-DOM');
all_from('lib/MooseX/DOM.pm');

requires 'Moose';
requires 'XML::LibXML';

test_requires 'Test::More';
test_requires 'Test::UseAllModules';

auto_include_deps;
WriteAll;

