#!perl
use utf8;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Functions qw/muse_to_object/;

my %tests = (
             'foo*bar*' => 'foo*bar*',
             '*foo*bar' => '*foo*bar',
             '*foo*,bar' => '<em>foo</em>,bar',
             'foo,*bar*' => 'foo,*bar*',
             '*foo*0bar' => '*foo*0bar',
             '*foo *bar*' => '<em>foo *bar</em>',
            );

foreach my $muse (keys %tests) {
    my $html = muse_to_object($muse)->as_html;
    $html =~ s/\s*<\/?p>\s*//g;
    is $html, $tests{$muse};
}


done_testing;
