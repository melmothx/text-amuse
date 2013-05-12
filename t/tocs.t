use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

plan tests => 11;

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

# print Dumper([$document->raw_html_toc]);

my $exp = [
           {
            'level' => '1',
            'index' => 1,
            'string' => 'Part'
           },
           {
            'level' => '2',
            'index' => 2,
            'string' => 'Chapter'
           },
           {
            'level' => '3',
            'index' => 3,
            'string' => 'Section'
           },
           {
            'level' => '4',
            'index' => 4,
            'string' => 'Subsection'
           },
           {
            'level' => '1',
            'index' => 5,
            'string' => 'Part (2)'
           },
           {
            'level' => '2',
            'index' => 6,
            'string' => 'Chapter (2)'
           },
           {
            'level' => '3',
            'index' => 7,
            'string' => 'Section (2)'
           },
           {
            'level' => '4',
            'index' => 8,
            'string' => 'Subsection (2)'
           }
          ];

is_deeply([$document->raw_html_toc], $exp, "Raw toc ok");


$document =
  Text::Amuse->new(file => catfile(t => testfiles => 'table.muse'));

ok($document->as_html);
ok(!$document->toc_as_html);
# print "<" . $document->toc_as_html . ">";
ok($document->as_latex);
ok(!$document->wants_toc);
is($document->toc_as_html, "");


