#!perl

use utf8;
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

 a. test

Hello there

                         a. pinco

                         Signed.<br>
                         A. Pallino
MUSE

    my $html = muse_to_html($muse);
    unlike ($html, qr{list-style-type}, "Not a list");
    my $doc = muse_to_object($muse);
    # parse
    my @parsed = $doc->document->elements;
    is (scalar(@parsed), 7, "Found 7 elements");
    my $false_list = $parsed[3];
    is ($false_list->type, 'regular');
    is ($false_list->block, 'right');
    print $doc->as_latex;
}

{
    my $muse =<<'MUSE';

  Signed.

  A. Prova

     A. Prova

        A. Prova

           A. Prova      
   
              viii. Prova





                    A. Pallinox

        A. Prova

           A. Prova      


MUSE
    my $html = muse_to_html($muse);
    like ($html, qr{list-style-type}, "It's a list");
    my $doc = muse_to_object($muse);
    my @parsed = $doc->document->elements;
    # print Dumper(\@parsed);
    my $list = $parsed[17];
    is ($list->type, 'li', "list is ok");
    is ($list->block, 'olA', "block is ok");
    is ($list->string, "Pallinox\n", "string is ok");
    #    print $doc->as_html;
}
