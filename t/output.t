use strict;
use warnings;
use Test::More;
use Text::AMuse;
use File::Spec::Functions;
use Data::Dumper;

my $document =
  Text::AMuse->new(file => catfile(t => testfiles => 'packing.muse'),
                   debug => 0);

ok($document->as_html);
ok($document->as_latex);
print $document->as_latex;

$document =
  Text::AMuse->new(file => catfile(t => testfiles => 'inline.muse'),
                   debug => 0);

ok($document->as_html);
ok($document->as_latex);
print $document->as_latex;
print $document->as_html;
done_testing;
