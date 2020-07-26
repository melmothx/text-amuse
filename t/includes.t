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

plan tests => 18;


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
                                                       undef,
                                                       File::Spec->catdir($FindBin::Bin, 'non-existent'),
                                                       $FindBin::Bin,
                                                       # twice, so we test if it doesn't include twice
                                                       $FindBin::Bin,
                                                      ]
                                    });
    is scalar($obj->included_files), 2, "Included files: " . Dumper([$obj->included_files]);
    eq_or_diff($obj->as_html, $expected_html);
    eq_or_diff($obj->as_latex, $expected_latex);
    unlike $obj->as_html, qr{\#include}, "string #included was replaced";
    is_deeply([ $obj->included_files],
              [
               File::Spec->catfile($FindBin::Bin, 'include', 'pippo.muse'),
               File::Spec->catfile($FindBin::Bin, 'include', 'pippo.txt'),
              ],
              "Only two paths are included (the valid ones)");
}
{
    my $obj = muse_to_object($muse);
    ok !scalar($obj->include_paths);
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

#include ../../../../../../../../../../../../../../../../../../../../../etc/passwd

{{{
#include ../../../../../../../../../../../../../../../../../../../../../etc/passwd
}}}
MUSE
    my $wd = File::Temp->newdir;
    my $file = File::Spec->catfile($wd, 'test.muse');
    open (my $fh, '>:encoding(UTF-8)', $file) or die $!;
    print $fh $malicious;
    close $fh;
    my $obj = Text::Amuse->new(file => $file,
                               include_paths => [
                                                 $FindBin::Bin,
                                                ],
                              );
    ok scalar($obj->include_paths);
    like $obj->as_html, qr{etc/passwd.*etc/passwd}s;
    ok !$obj->included_files;
}

{
    my $malicious = <<MUSE;
#title Try inclusion

; exists, but the .. invalidates it.

#include include/../include/pippo.muse

#include include/./pippo.muse

#include include/./pippo.muse
MUSE
    my $obj = muse_to_object($malicious, {
                                          include_paths => [
                                                            $FindBin::Bin,
                                                           ],
                                          });
    ok scalar($obj->include_paths);
    ok !$obj->included_files;
    my $exp_html = <<'HTML';
<div class="comment" style="display:none">exists, but the .. invalidates it.</div>

<p>
<a id="text-amuse-label-include" class="text-amuse-internal-anchor"></a>
include/../include/pippo.muse
</p>

<p>
<a id="text-amuse-label-include" class="text-amuse-internal-anchor"></a>
include/./pippo.muse
</p>

<p>
<a id="text-amuse-label-include" class="text-amuse-internal-anchor"></a>
include/./pippo.muse
</p>
HTML
    eq_or_diff $obj->as_html, $exp_html, "HTML OK";
    my $exp_latex = <<'LATEX';
% exists, but the .. invalidates it.

\hyperdef{amuse}{include}{}%
\label{textamuse:include}%
include\Slash{}..\Slash{}include\Slash{}pippo.muse


\hyperdef{amuse}{include}{}%
\label{textamuse:include}%
include\Slash{}.\Slash{}pippo.muse


\hyperdef{amuse}{include}{}%
\label{textamuse:include}%
include\Slash{}.\Slash{}pippo.muse

LATEX
    eq_or_diff $obj->as_latex, $exp_latex, "LaTeX OK";
}
