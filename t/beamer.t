#!perl

use strict;
use warnings;

use Text::Amuse;
use Data::Dumper;
use File::Spec::Functions qw/catfile tmpdir/;
use Test::More tests => 1;

my $doc =
  Text::Amuse->new(file => catfile(t => testfiles => 'beamer.muse'),
                   debug => 0);

print Dumper($doc->_latex_obj->process);

ok $doc->as_beamer;


