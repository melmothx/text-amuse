use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions;
use Data::Dumper;
use File::Temp;

eval "use Test::Memory::Cycle";
if ($@) {
    plan skip_all => "Test::Memory::Cycle required for testing memory cycles";
    exit;
}


eval "use Devel::Size";
if ($@) {
    plan skip_all => "Devel::Size required for testing memory usage";
    exit;
}

plan tests => 10;





my $document;
foreach my $file (qw/packing.muse
                     footnotes.muse/) {
    $document =
      Text::Amuse->new(file => catfile(t => testfiles => $file),
                       debug => 1);
    ok($document->as_html, "HTML produced");
    ok($document->as_latex, "LaTeX produced");
    memory_cycle_ok($document, "Memory cycles OK");
}

$document =
  Text::Amuse->new(file => catfile(t => testfiles => "recursiv.muse"));

diag $document->as_html;
diag $document->as_latex;

# create a document with

# say a 4M document

my $temp = File::Temp->new(TEMPLATE => "XXXXXXXXXX",
                           SUFFIX => ".muse",
                           TMPDIR => 1);

diag "Using " . $temp->filename;

for my $num (1..10_000) {
    my $line = "helo " x 100;
    print $temp "$line\n\n" ;
}

close $temp;

my $size = -s $temp->filename;
diag "Size is $size";

my $doc = Text::Amuse->new(file => $temp->filename);

ok($doc->as_html);
ok($doc->as_latex);
ok($doc->as_splat_html);

my $totalsize = Devel::Size::total_size($doc);
ok(($totalsize  < 40_000_000), "Size lesser than 40 Mb ("
   . sprintf('%0.3f', $totalsize / 1_000_000) . " Mb)");




