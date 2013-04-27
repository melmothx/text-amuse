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
$document =
  Text::AMuse->new(file => catfile(t => testfiles => 'inline.muse'),
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


<script>alert("hacked!")</script><em><strong>

TEX
is($document->as_html, $exphtml);
is($document->as_latex, $exptex);

$document = Text::AMuse->new(file => catfile(t => testfiles => 'footnotes.muse'),
                             debug => 0);


$exptex = <<'TEX';

Hello\footnote{first} two\footnote{second third} three\footnote{third}

TEX

$exphtml = <<'HTML';

<p>Hello <a href="#fn1" class="footnote" id="fn_back1">[1]</a> two <a href="#fn2" class="footnote" id="fn_back2">[2]</a> three <a href="#fn3" class="footnote" id="fn_back3">[3]</a></p>

<p class="fnline"><a class="footnotebody" href="#fn_back1 id="fn1">[1]</a>first
</p>

<p class="fnline"><a class="footnotebody" href="#fn_back2 id="fn2">[2]</a>second
third
</p>

<p class="fnline"><a class="footnotebody" href="#fn_back3 id="fn3">[3]</a>third
</p>
HTML

is($document->as_html, $exphtml);
is($document->as_latex, $exptex);

done_testing;
