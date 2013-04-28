use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;
use t::Utils qw/read_file write_to_file/;

plan tests => 22;

my $document =
  Text::Amuse->new(file => catfile(t => testfiles => 'packing.muse'),
                   debug => 0);

ok($document->as_html);
ok($document->as_latex);
$document =
  Text::Amuse->new(file => catfile(t => testfiles => 'inline.muse'),
                   debug => 0);

my $exphtml = << 'HTML';

<p><em>em</em> <br /> <strong>strong</strong> <br /> <strong><em>emStrong</em></strong> <code>code</code> <em>em</em>
<strong>strong</strong> <em><strong>EmStrong</em></strong>
<em>em</em> <strong>strong</strong> <strong><em>emStrong</em></strong> <code>code</code> <em>em</em>
<strong>strong</strong> <em><strong>EmStrong</em></strong></p>

<p>&lt;script&gt;alert(&quot;hacked!&quot;)&lt;/script&gt;&lt;em&gt;&lt;strong&gt;</p>
HTML

my $exptex = << 'TEX';

\emph{em} \forcelinebreak  \textbf{strong} \forcelinebreak  \textbf{\emph{emStrong}} \texttt{code} \emph{em}
\textbf{strong} \emph{\textbf{EmStrong}}
\emph{em} \textbf{strong} \textbf{\emph{emStrong}} \texttt{code} \emph{em}
\textbf{strong} \emph{\textbf{EmStrong}}


<script>alert("hacked!")<\Slash{}script><em><strong>

TEX
is($document->as_html, $exphtml);
is($document->as_latex, $exptex);


test_testfile("comments");
test_testfile("footnotes");
test_testfile("verse");
test_testfile("example-3");
test_testfile("table");
test_testfile("links");
test_testfile("special");
test_testfile("breaklist");
test_testfile("verse-2");

sub test_testfile {
    my $base = shift;
    $document = Text::Amuse->new(file => catfile(t => testfiles => "$base.muse"),
                                 debug => 0);
    write_to_file(catfile(tmpdir() => "$base.out.html"), $document->as_html);
    write_to_file(catfile(tmpdir() => "$base.out.ltx"), $document->as_latex);
    my $latex = read_file(catfile(t => testfiles => "$base.exp.ltx"));
    my $html = read_file(catfile(t => testfiles => "$base.exp.html"));
    is ($document->as_latex, $latex, "LaTex for $base OK");
    is ($document->as_html, $html, "HTML for $base OK");
}
