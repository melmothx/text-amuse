use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

plan tests => 10;

my $document =
  Text::Amuse->new(file => catfile(t => testfiles => 'headings.muse'));

my $htmltoc =<<'EOF';
<p class="tableofcontentline toclevel1"><span class="tocprefix">&nbsp;&nbsp;</span><a href="#toc1">Part</a></p>
<p class="tableofcontentline toclevel2"><span class="tocprefix">&nbsp;&nbsp;&nbsp;&nbsp;</span><a href="#toc2">Chapter</a></p>
<p class="tableofcontentline toclevel3"><span class="tocprefix">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><a href="#toc3">Section</a></p>
<p class="tableofcontentline toclevel4"><span class="tocprefix">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><a href="#toc4">Subsection</a></p>
<p class="tableofcontentline toclevel1"><span class="tocprefix">&nbsp;&nbsp;</span><a href="#toc5">Part (2)</a></p>
<p class="tableofcontentline toclevel2"><span class="tocprefix">&nbsp;&nbsp;&nbsp;&nbsp;</span><a href="#toc6">Chapter (2)</a></p>
<p class="tableofcontentline toclevel3"><span class="tocprefix">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><a href="#toc7">Section (2)</a></p>
<p class="tableofcontentline toclevel4"><span class="tocprefix">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><a href="#toc8">Subsection (2)</a></p>
EOF

ok($document->as_html);
ok($document->toc_as_html);
is($document->toc_as_html, $htmltoc, "ToC looks good");
ok($document->as_latex);
ok($document->wants_toc);

print $document->toc_as_html, "\n";


$document =
  Text::Amuse->new(file => catfile(t => testfiles => 'table.muse'));

ok($document->as_html);
ok(!$document->toc_as_html);
# print "<" . $document->toc_as_html . ">";
ok($document->as_latex);
ok(!$document->wants_toc);
is($document->toc_as_html, "");

