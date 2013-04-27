use 5.010001;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Document;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 1;

my $fn = Text::Amuse::Document->new(file => catfile(t => testfiles => 'broken.muse'));

ok($fn->document);
