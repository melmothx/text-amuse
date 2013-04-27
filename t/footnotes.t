use 5.010001;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Document;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 6;

my $fn = Text::Amuse::Document->new(file => catfile(t => testfiles => 'footnotes.muse'));

my @got = $fn->document;

is(scalar @got, 1, "Only one element");

is($fn->get_footnote(1)->string, "first\n");
is($fn->get_footnote(2)->string, "second\nthird\n");
is($fn->get_footnote(3)->string, "third\n");
is($fn->get_footnote(), undef);
is($fn->get_footnote(4), undef);
