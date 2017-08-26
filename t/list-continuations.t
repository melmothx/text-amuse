#!perl

use strict;
use warnings;
use File::Spec::Functions qw/catfile/;
use Text::Amuse::Document;
use Data::Dumper;
use Test::More tests => 11;

my $doc = Text::Amuse::Document->new(file => catfile(qw/t testfiles enumerations.muse/));

ok $doc->_list_index_map;
is $doc->_list_index_map->{'a.'}, 1;
is $doc->_list_index_map->{'i.'}, 1;
is $doc->_list_index_map->{'v.'}, 5;
is $doc->_list_index_map->{'x.'}, 10;
is $doc->_list_index_map->{'l.'}, 50;
is $doc->_list_index_map->{'A.'}, 1;
is $doc->_list_index_map->{'I.'}, 1;
is $doc->_list_index_map->{'V.'}, 5;
is $doc->_list_index_map->{'X.'}, 10;
is $doc->_list_index_map->{'L.'}, 50;


