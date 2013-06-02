use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions;
use Data::Dumper;

eval "use Test::Memory::Cycle";
if ($@) {
    plan skip_all => "Test::Memory::Cycle required for testing memory cycles";
}
else {
    plan tests => 6;
}


my $document;
foreach my $file (qw/packing.muse
                     footnotes.muse/) {
    $document =
      Text::Amuse->new(file => catfile(t => testfiles => $file),
                       debug => 1);
    ok($document->as_html);
    ok($document->as_latex);
    memory_cycle_ok($document)
}

$document =
  Text::Amuse->new(file => catfile(t => testfiles => "recursiv.muse"));

print $document->as_html;
print $document->as_latex;
