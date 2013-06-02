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

plan tests => 54;

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


test_testfile("comments");
test_testfile("footnotes");
test_testfile("verse");
test_testfile("example-3");
test_testfile("table");
test_testfile("links");
test_testfile("special");
test_testfile("breaklist");
test_testfile("verse-2");
test_testfile("headings");
test_testfile("table-2");
test_testfile("uneven-table");
test_testfile("table-square-brackets");
test_testfile("nbsp");
test_testfile("links-2");
test_testfile("10_theses");
test_testfile("broken");
test_testfile("broken2");
test_testfile("broken3");
test_testfile("list-and-fn");
test_testfile("complete");
test_testfile("right");
test_testfile("square-brackets");
test_testfile("verbatim");
test_testfile("images");

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
    is_deeply ([ split /\n/, $document->as_latex ],
               [ split /\n/, $latex ],
               "LaTex for $base OK");
    is_deeply ([ split /\n/, $document->as_html ],
               [ split /\n/, $html],
               "HTML for $base OK");
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
