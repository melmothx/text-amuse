#!perl

use strict;
use warnings;
use Test::More;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_to_object/;
use Data::Dumper;
use FindBin;
use File::Temp;
use File::Spec;

BEGIN {
    if (!eval q{ use Test::Differences; unified_diff; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

plan tests => 10;


# test with or without leading /, same thing.

my $muse = <<MUSE;
#title Try inclusion

Body begins

#include include/pippo.muse

{{{
#include ///include/pippo.txt
}}}
MUSE

my $expected_html =<<'HTML';

<p>
Body begins
</p>

<ul>
<li>
<p>
Hello
</p>

</li>
<li>
<p>
There
</p>

</li>

</ul>

<pre class="example">
# -*- this is a configuration file

</pre>
HTML

my $expected_latex =<<'LATEX';

Body begins


\begin{itemize}
\item\relax 
Hello



\item\relax 
There




\end{itemize}

\begin{alltt}
\# -*- this is a configuration file

\end{alltt}

LATEX




{
    my $obj = muse_to_object($muse, {
                                     include_paths => [
                                                       File::Spec->catdir($FindBin::Bin, 'non-existent'),
                                                       $FindBin::Bin,
                                                       # twice, so we test if it doesn't include twice
                                                       $FindBin::Bin,
                                                      ]
                                    });
    eq_or_diff($obj->as_html, $expected_html);
    eq_or_diff($obj->as_latex, $expected_latex);
    is scalar($obj->included_files), 2, "Included files: " . Dumper([$obj->included_files]);
    unlike $obj->as_html, qr{\#include}, "string #included was replaced";
}
{
    my $obj = muse_to_object($muse);
    diag Dumper([ $obj->include_paths ]);
    is(scalar($obj->included_files), 0, "Nothing included") or diag Dumper([$obj->included_files]);
    like $obj->as_html, qr{pippo\.muse}, "string #included is still there";
    like $obj->as_html, qr{pippo\.txt}, "string #included is still there";
    like $obj->as_latex, qr{pippo\.muse}, "string #included is still there";
    like $obj->as_latex, qr{pippo\.txt}, "string #included is still there";
}


# test traversals

{
    my $malicious = <<MUSE;
#title Try inclusion

Body begins

#include ///

#include ../../../../../../../../../../../../../../../../../../../../../etc/passwd/etc/passwd

{{{
#include ../../../../../../../../../../../../../../../../../../../../../etc/passwd
}}}
MUSE
    my $wd = File::Temp->newdir;
    my $file = File::Spec->catfile($wd, 'test.muse');
    open (my $fh, '>:encoding(UTF-8)', $file) or die $!;
    print $fh $malicious;
    close $fh;
    my $obj = Text::Amuse->new(file => $file);
    diag $obj->as_latex;
    ok !$obj->included_files;
}
