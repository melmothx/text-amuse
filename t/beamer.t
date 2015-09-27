#!perl

use strict;
use warnings;

use Text::Amuse;
use Text::Amuse::Functions qw/muse_to_object/;
use Data::Dumper;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 5;
use File::Temp;

my $doc =
  Text::Amuse->new(file => catfile(t => testfiles => 'beamer.muse'),
                   debug => 0);

my $body = $doc->as_beamer;
ok($body, "beamer body produced");
unlike($body, qr/ignore/, "Ignored parts are ignored");
like($body, qr/Subsubsection.*This.*is.*the.*list/s, "Found the first list");

if ($ENV{RELEASE_TESTING}) {
    # check if it compiles;
    my $body = $doc->as_beamer;
    my $tex =<<'TEX';
\documentclass{beamer}
\usepackage{beamerthemesplit}
\usepackage{fontspec}
\usepackage{polyglossia}
\setmainfont{Linux Libertine O}
\setmainlanguage{english}
\newcommand*{\chapter}[1]{\part{#1}}
\usepackage{alltt}
\usepackage{verbatim}
\begin{document}
TEX
    my $testdir = catdir(qw/t beamer/);
    mkdir $testdir unless -d $testdir;
    chdir $testdir or die "Cannot chdir into $testdir: $!";
    my $out = 'beamer-test.tex';
    write_to_file($out, $tex, $doc->as_beamer, "\\end{document}\n");
    for (1..3) {
        system(xelatex => '-interaction=batchmode', $out);
    }
    $out =~ s/tex$/pdf/;
    diag "Output on " . catfile($testdir, $out). "\n";
}

$doc = muse_to_object("#title Test\n\nblablabla\n\nbalbal\n");
ok ($doc->as_latex, "LaTeX output ok");
is ('', $doc->as_beamer, "beamer yields an empty string when there is no section");


sub write_to_file {
    my ($file, @stuff) = @_;
    open (my $fh, ">:encoding(utf-8)", $file) or die "Couldn't open $file $!";
    print $fh @stuff;
    close $fh;
}
