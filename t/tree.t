#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Text::Amuse::Document::Block;

my $nocycles;
eval "use Test::Memory::Cycle";
if ($@) {
    $nocycles => 1;
}

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Deparse = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys = 1;

plan tests => 6;

my $root = Text::Amuse::Document::Block->new(type => 'root');

my $child = $root->spawn;
$root->spawn for 1..4;

my $grand_child = $child->spawn;

is $grand_child->root->type, 'root';
is $root->root->type, 'root';
is $child->root->type, 'root';
is scalar($root->children), 5;
my (@children)  = $root->children;
$children[4]->spawn;
print Dumper($root);

SKIP: {
    skip "No Test::Memory::Cycle installed", 2 if $nocycles;
    memory_cycle_ok($root, "No leaking, hopefully");
    weakened_memory_cycle_exists($root, "Weakened memory cycles present");
};

1;
