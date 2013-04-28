use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;
use t::Utils qw/read_file write_to_file/;

plan tests => 2;

my $document =
  Text::Amuse->new(file => catfile(t => testfiles => 'breaklist.muse'),
                   debug => 0);

ok($document->as_latex);
ok($document->as_html);

