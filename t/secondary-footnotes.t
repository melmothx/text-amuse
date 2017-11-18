use strict;
use warnings;
use Test::More;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_to_html muse_to_tex/;
use File::Spec::Functions;
use Data::Dumper::Concise;

plan tests => 24;

my $file = catfile(t => testfiles => 'secondary-fn.muse');

my $muse = Text::Amuse->new(file => $file);
my $doc = $muse->document;
my @got = $doc->elements;

{
    # diag Dumper([ values %{$doc->_raw_footnotes}]);
    my ($sample) = grep { $_->type eq 'regular' and $_->string =~ m/\[\*\]/ } @got;
    # diag Dumper($sample);
    my @footnotes = $doc->get_secondary_footnotes($sample, 2);
    is scalar(@footnotes), 2;
    diag Dumper(\@footnotes);
}

print $muse->as_latex;

