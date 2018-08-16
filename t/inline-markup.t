#!perl
use utf8;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Functions qw/muse_to_object/;

my @tests = (
             [ '*foo' => '*foo',                   ],
             [ 'foo*bar*' => 'foo*bar*',           ],
             [ '*foo*bar' => '*foo*bar',           ],
             [ '*foo*,bar' => '<em>foo</em>,bar',  ],
             [ 'foo,*bar*' => 'foo,*bar*',         ],
             [ '*foo*0bar' => '*foo*0bar',         ],
             [ '*foo *bar*' => '<em>foo *bar</em>',],

             [ 'material *foo'       => 'material *foo',              ],
             [ 'material foo*bar*'   => 'material foo*bar*',          ],
             [ 'material *foo*bar'   => 'material *foo*bar',          ],
             [ 'material *foo*,bar'  => 'material <em>foo</em>,bar',  ],
             [ 'material foo,*bar*'  => 'material foo,*bar*',         ],
             [ 'material *foo*0bar'  => 'material *foo*0bar',         ],
             [ 'material *foo *bar*' => 'material <em>foo *bar</em>', ],

            );

plan tests => scalar(@tests);

foreach my $test (@tests) {
    my $html = muse_to_object($test->[0])->as_html;
    $html =~ s/\s*<\/?p>\s*//g;
    is $html, $test->[1], "$test->[0] => $test->[1]";
}
