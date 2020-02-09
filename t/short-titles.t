#!perl

use utf8;
use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

plan tests => 1;

my $doc = Text::Amuse->new(file => catfile(qw/t testfiles titles-short.muse/));

diag Dumper([$doc->raw_html_toc]);

is_deeply([$doc->raw_html_toc],
          [
           {
            'index' => 1,
            'level' => '1',
            'string' => 'Short',
           },
           {
            'string' => 'Short',
            'level' => '2',
            'index' => 2
           },
           {
            'index' => 3,
            'level' => '3',
            'string' => 'Short',
           },
          ],
          "ToC is OK");

diag $doc->toc_as_html;

