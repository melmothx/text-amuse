use 5.010001;
use strict;
use warnings;
use Test::More;
use Text::AMuse;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 1;

my $fn = Text::AMuse->new(file => catfile(t => testfiles => 'broken.muse'));

ok($fn->document);
