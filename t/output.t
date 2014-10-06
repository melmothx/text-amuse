use strict;
use warnings;
use utf8;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

 # my $builder = Test::More->builder;
 # binmode $builder->output,         ":utf8";
 # binmode $builder->failure_output, ":utf8";
 # binmode $builder->todo_output,    ":utf8";

my $leave_out_in_tmp = 0;

plan tests => 68;

my $document =
  Text::Amuse->new(file => catfile(t => testfiles => 'packing.muse'),
                   debug => 0);

ok($document->as_html);
ok($document->as_latex);
$document =
  Text::Amuse->new(file => catfile(t => testfiles => 'inline.muse'),
                   debug => 0);

my $exphtml = << 'HTML';

<p>
<em>em</em> <br /> <strong>strong</strong> <br /> <strong><em>emStrong</em></strong> <code>code</code> <em>em</em>
<strong>strong</strong> <em><strong>EmStrong</em></strong>
<em>em</em> <strong>strong</strong> <strong><em>emStrong</em></strong> <code>code</code> <em>em</em>
<strong>strong</strong> <em><strong>EmStrong</em></strong>
</p>

<p>
&lt;script&gt;alert(&quot;hacked!&quot;)&lt;/script&gt;&lt;em&gt;&lt;strong&gt;
</p>
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


foreach my $testfile (qw/comments
                         footnotes
                         verse
                         example-3
                         table
                         links
                         special
                         breaklist
                         verse-2
                         headings
                         table-2
                         uneven-table
                         table-square-brackets
                         nbsp
                         links-2
                         10_theses
                         broken
                         broken2
                         broken3
                         list-and-fn
                         complete
                         right
                         square-brackets
                         verbatim
                         images
                         captions
                         image2
                         table-captions
                         pagebreaks
                         zeros
                         headings-with-fn
                         manual
                        /) {
    test_testfile($testfile);
}

sub test_testfile {
    my $base = shift;
    $document = Text::Amuse->new(file => catfile(t => testfiles => "$base.muse"),
                                 debug => 0);
    if ($leave_out_in_tmp) {
        write_to_file(catfile(tmpdir() => "$base.out.html"),
                      $document->as_html);
        write_to_file(catfile(tmpdir() => "$base.out.ltx"),
                      $document->as_latex);
    }
    my $latex = read_file(catfile(t => testfiles => "$base.exp.ltx"));
    my $html = read_file(catfile(t => testfiles => "$base.exp.html"));
    my @exp = split /\n/, $latex;
    my @got = split /\n/, $document->as_latex;
    is_deeply (\@got, \@exp, "LaTex for $base OK") or diag Dumper(\@got, \@exp);
    @exp = split /\n/, $html;
    @got = split /\n/, $document->as_html;
    is_deeply (\@got, \@exp, "HTML for $base OK") or diag Dumper(\@got, \@exp);
    # print Dumper($document->document);
}

sub write_to_file {
    my ($file, @stuff) = @_;
    open (my $fh, ">:encoding(utf-8)", $file) or die "Couldn't open $file $!";
    print $fh @stuff;
    close $fh;
}

sub read_file {
    my $file = shift;
    local $/ = undef;
    open (my $fh, "<:encoding(utf-8)", $file) or die "Couldn't open $file $!";
    my $string = <$fh>;
    close $fh;
    return $string;
}
