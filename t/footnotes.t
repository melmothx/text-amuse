use 5.010001;
use strict;
use warnings;
use Test::More;
use Text::AMuse;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 6;

my $fn = Text::AMuse->new(file => catfile(t => testfiles => 'footnotes.muse'));

my @got = $fn->document;

is(scalar @got, 1, "Only one element");

is($fn->get_footnote(1), "first\n");
is($fn->get_footnote(2), "second\n");
is($fn->get_footnote(3), "third\n");
is($fn->get_footnote(), undef);
is($fn->get_footnote(4), undef);
