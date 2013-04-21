use strict;
use warnings;
use Test::More;
use Text::AMuse;
use File::Spec::Functions;
use Data::Dumper;
use Test::Memory::Cycle;

plan tests => 3;

my $document =
  Text::AMuse->new(file => catfile(t => testfiles => 'packing.muse'),
                   debug => 0);

ok($document->as_html);
ok($document->as_latex);

memory_cycle_ok($document);

