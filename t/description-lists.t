#!perl

use strict;
use warnings;
use Text::Amuse;
use Data::Dumper;
use File::Spec::Functions qw/catfile/;
use Test::More tests => 2;
my $doc = Text::Amuse->new(file => catfile(qw/t testfiles desc-lists.muse/));

like ($doc->as_html,
      qr!<dl>\s*<dt>term</dt>\s*<dd>\s*<p>\s*definition\s*</p>\s*</dd>.*</dl>!s,
      "HTML appears fine");
like ($doc->as_latex,
      qr!\\begin\{description\}\s*\\item\[\{term\}\]\s*definition\s.*\\end\{description\}!s,
      "LaTeX appears fine");


