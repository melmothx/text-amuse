#!perl

use strict;
use warnings;
use Test::More tests => 8;
use Text::Amuse::Functions qw/muse_to_html
                              muse_to_tex
                              muse_to_object
                             /;

use Data::Dumper;

{
    my $muse =<<'MUSE';

  Signed.

                                A. Pallino
MUSE

    my $html = muse_to_html($muse);
    unlike ($html, qr{list-style-type}, "Not a list");
    my $doc = muse_to_object($muse);
    # parse
    my @parsed = $doc->document->parsed_body;
    is (scalar(@parsed), 6, "Found 6 elements");
    print Dumper(\@parsed);
    my $false_list = $parsed[3];
    is ($false_list->type, 'regular');
    is ($false_list->block, 'right');
}

{
    my $muse =<<'MUSE';

  Signed.

  A. Prova

     A. Prova

          A. Prova

              A. Prova      
   
                    A. Prova
     
                         A. Pallinox
MUSE
    my $html = muse_to_html($muse);
    like ($html, qr{list-style-type}, "It's a list");
    my $doc = muse_to_object($muse);
    my @parsed = $doc->document->parsed_body;
    print Dumper(\@parsed);
    my $list = $parsed[13];
    is ($list->type, 'li', "list is ok");
    is ($list->block, 'olA', "block is ok");
    is ($list->string, "Pallinox\n", "string is ok");
    print $doc->as_latex;
}
