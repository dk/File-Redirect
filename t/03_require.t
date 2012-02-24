#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use File::Redirect qw(mount);

mount( 'Simple', { '/Foo.pm' => 'package Foo; sub foo { print qq(Hello world!\n)}; 1' }, 'redirect:');

use lib qw(redirect:);

require Foo;

ok(1, 'require');

Foo::foo();

ok(1, 'compiled');
