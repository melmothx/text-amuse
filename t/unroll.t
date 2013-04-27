use 5.010001;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Document;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 1;

my $list = Text::Amuse::Document->new(file => catfile(t => testfiles => 'unroll.muse'));

my @got;

foreach my $e ($list->document) {
    next if $e->type eq 'null';
    push @got, {
                block => $e->block,
                type  => $e->type,
                string => $e->string,
               }
}

my @expected = (
                {
                 'string' => '',
                 'type' => 'startblock',
                 'block' => 'quote'
                },
                {
                 'string' => 'hello
',
                 'type' => 'regular',
                 'block' => 'regular'
                },
                {
                 'string' => '',
                 'type' => 'stopblock',
                 'block' => 'quote'
                },
                {
                 'string' => '',
                 'type' => 'startblock',
                 'block' => 'center'
                },
                {
                 'string' => 'center
',
                 'type' => 'regular',
                 'block' => 'regular'
                },
                {
                 'string' => '',
                 'type' => 'stopblock',
                 'block' => 'center'
                },
                {
                 'string' => '',
                 'type' => 'startblock',
                 'block' => 'right'
                },
                {
                 'string' => 'right
',
                 'type' => 'regular',
                 'block' => 'regular'
                },
                {
                 'string' => '',
                 'type' => 'stopblock',
                 'block' => 'right'
                }
               );

is_deeply(\@got, \@expected);
