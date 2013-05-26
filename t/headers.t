use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

plan tests => 10;

my $document =
  Text::Amuse->new(file => catfile(t => testfiles => 'headers.muse'),
                   debug => 0);

ok($document->as_html);
ok($document->as_latex);
ok($document->header_as_latex);
ok($document->header_as_html);

is($document->as_html, "\n<p>\nHello\n</p>\n");
is($document->as_latex, "\nHello\n\n");

is_deeply($document->header_as_latex,
          {
           title => '\\emph{Title}',
           author => '\\textbf{Prova}',
           date => '<script>hello("a")\'<\\Slash{}script>',
           comment => '[1] [1] [1]',
           subtitle => 'Here we \\textbf{go}',
           bla => '\\emph{hem} \\textbf{ehm} \\textbf{\\emph{bla}}',
          }, "LaTeX header ok");

is_deeply($document->header_as_html,
          {
           title => '<em>Title</em>',
           author =>  '<strong>Prova</strong>',
           date => '&lt;script&gt;hello(&quot;a&quot;)&#x27;&lt;/script&gt;',
           comment => '[1] [1] [1]',
           subtitle => 'Here we <strong>go</strong>',
           bla => '<em>hem</em> <strong>ehm</strong> <strong><em>bla</em></strong>',
          }, "HTML header ok");

is_deeply($document->header_as_latex,
          {
           title => '\\emph{Title}',
           author => '\\textbf{Prova}',
           date => '<script>hello("a")\'<\\Slash{}script>',
           comment => '[1] [1] [1]',
           subtitle => 'Here we \\textbf{go}',
           bla => '\\emph{hem} \\textbf{ehm} \\textbf{\\emph{bla}}',
          }, "LaTeX header ok");

is_deeply($document->header_as_html,
          {
           title => '<em>Title</em>',
           author =>  '<strong>Prova</strong>',
           date => '&lt;script&gt;hello(&quot;a&quot;)&#x27;&lt;/script&gt;',
           comment => '[1] [1] [1]',
           subtitle => 'Here we <strong>go</strong>',
           bla => '<em>hem</em> <strong>ehm</strong> <strong><em>bla</em></strong>',
          }, "HTML header ok");

