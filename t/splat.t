use strict;
use warnings;
use Data::Dumper;
use Text::Amuse::Document;
use Text::Amuse::Output;
use File::Spec::Functions;
use Test::More;

plan tests => 1;

my $file = catfile(t => testfiles => "splat.muse");
my $doc = Text::Amuse::Document->new(file => $file);
my $output = Text::Amuse::Output->new(document => $doc,
                                      format => 'html');

my $splat = $output->process(split => 1);

my $expected =  [
                 '<h2 id="toc1">Here</h2>


<p>Here there is the body <a href="#fn1" class="footnote" id="fn_back1">[1]</a></p>

<p class="fnline"><a class="footnotebody" href="#fn_back1" id="fn1">[1]</a> First
</p>
',


                 '<h3 id="toc2">chapter</h3>


<p>Here we go <a href="#fn2" class="footnote" id="fn_back2">[2]</a></p>

<p class="fnline"><a class="footnotebody" href="#fn_back2" id="fn2">[2]</a> Second
</p>
',


                 '<h4 id="toc3">section <a href="#fn3" class="footnote" id="fn_back3">[3]</a></h4>


<p>section <a href="#fn4" class="footnote" id="fn_back4">[4]</a></p>

<p>End of the game</p>

<p class="fnline"><a class="footnotebody" href="#fn_back3" id="fn3">[3]</a> Third
</p>

<p class="fnline"><a class="footnotebody" href="#fn_back4" id="fn4">[4]</a> Fourth
</p>
'
                ];


is_deeply($expected, $splat, "Splat html OK");

