use strict;
use warnings;
use Test::More;
use Text::AMuse;
use File::Spec::Functions;
use Data::Dumper;
use Test::Memory::Cycle;

plan tests => 6;

my $document;
foreach my $file (qw/packing.muse
                     footnotes.muse/) {
    $document =
      Text::AMuse->new(file => catfile(t => testfiles => $file),
                       debug => 1);
    ok($document->as_html);
    ok($document->as_latex);
    memory_cycle_ok($document)
}
