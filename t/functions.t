use strict;
use warnings;
use utf8;
use Test::More;
use Text::Amuse::Functions qw/muse_format_line/;

plan tests => 8;

is(muse_format_line(html => q{<em>ciao</em>bella<script">}),
   "<em>ciao</em>bella&lt;script&quot;&gt;");
is(muse_format_line(ltx => "<em>ciao</em>bella</script>"),
   q{\emph{ciao}bella<\Slash{}script>});

is(muse_format_line(html => "[1] hello [1] [2]"), "[1] hello [1] [2]");
is(muse_format_line(ltx => "[1] hello [1] [2]"), "[1] hello [1] [2]");

is(muse_format_line(html => "* ***hello***"),
   "* <strong><em>hello</em></strong>");
is(muse_format_line(ltx => "* ***hello***"),
   '* \textbf{\emph{hello}}');


is(muse_format_line(html => "[1] [[http://pippo.org][mylink]]"),
   q{[1] <a href="http://pippo.org">mylink</a>});
is(muse_format_line(ltx => "[1] [[http://pippo.org][mylink]]"),
  q([1] \href{http://pippo.org}{mylink}));

