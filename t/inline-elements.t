#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Text::Amuse::Document;
use Text::Amuse::Output;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Deparse = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys = 1;

use File::Spec::Functions(qw/catfile/);

my $doc = Text::Amuse::Document->new(file => catfile(t => testfiles => 'broken-tags.muse'));

foreach my $fmt (qw/ltx html/) {
    my $out = Text::Amuse::Output->new(document => $doc,
                                       format => $fmt);

    {
        my @out = $out->inline_elements('<em>This is a [1] long string with [[http://example.com][<strong><em>strong</em></strong>]] emph</em> and some material');
        ok scalar(@out);
        diag Dumper(\@out);
    }
    {
        my @out = $out->inline_elements('**This *is* a [1] long string** with [[http://example.com][<strong><em>strong</em></strong>]] <em>emph</em> and {3} =some= material');
        ok scalar(@out);
        diag Dumper(\@out);
    }
}

