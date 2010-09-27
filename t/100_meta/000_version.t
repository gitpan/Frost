#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 1;
#use Test::More 'no_plan';

use Frost();

diag 'VERSIONS:';
diag 'Perl  ' . $];
diag 'Moose ' . $Moose::VERSION;
diag 'Frost ' . $Frost::VERSION;

ok 1;
