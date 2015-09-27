#!perl

use strict;
use warnings;

use Text::Amuse;
use Data::Dumper;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 1;
use File::Temp;

my $doc =
  Text::Amuse->new(file => catfile(t => testfiles => 'beamer.muse'),
                   debug => 0);

ok($doc->as_beamer);

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
        system(xelatex => $out);
    }
    $out =~ s/tex$/pdf/;
    diag "Output on " . catfile($testdir, $out). "\n";
}



sub write_to_file {
    my ($file, @stuff) = @_;
    open (my $fh, ">:encoding(utf-8)", $file) or die "Couldn't open $file $!";
    print $fh @stuff;
    close $fh;
}
