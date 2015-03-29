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

Prova

<example>

                         Signed.<br>
                         A. Pallino

</example>

<verse>
Prova
    Prova
</verse>

> this is a verse
>
>   And This is the same

 a. test

MUSE

    my $doc = muse_to_object($muse);
    my @elements = $doc->document->document;
    print Dumper(\@elements);
    is $elements[1]->type, 'example';
    is $elements[2]->type, 'verse';
    # is $elements[3]->type, 'verse';
    ok ($doc->as_html);
    print $doc->as_html;
    print $doc->as_latex;
}

