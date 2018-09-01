#!perl
use utf8;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Functions qw/muse_to_object/;

my @tests = (
             # no closing
             [ '*foo' => '*foo',                   ],
             # no open
             [ 'foo*' => 'foo*',                   ],
             # middle of a word
             [ 'foo*bar*' => 'foo*bar*',           ],
             [ '*foo*bar' => '*foo*bar',           ],
             [ '*foo*0bar' => '*foo*0bar',         ],
             [ '*foo*_underscore' => '*foo*_underscore' ],

             # symmetry
             [ '*foo*,bar' => '<em>foo</em>,bar',  ],
             [ 'foo,*bar*' => 'foo,<em>bar</em>',  ],

             [ '**foo**,bar' => '<strong>foo</strong>,bar',  ],
             [ 'foo,**bar**' => 'foo,<strong>bar</strong>',  ],

             [ 'foo_*bar*_baz' => 'foo_*bar*_baz' ],
             [ 'foo-*bar*-baz' => 'foo-<em>bar</em>-baz' ],
             [ 'foo_*bar*-baz' => 'foo_*bar*-baz' ],
             [ 'foo-*bar*_baz' => 'foo-*bar*_baz' ],


             # confusing input, got outclosed, garbage in/garbage out.
             [ '*foo *bar*' => "<em>foo <em>bar</em>\n</em>", {skip_adding => 1}],

             # second * is clearly not a markup element
             [ '*foo * bar*' => '<em>foo * bar</em>',],
             [ '**foo ** bar**' => '<strong>foo ** bar</strong>',],
             [ '***foo *** bar***' => '<strong><em>foo *** bar</em></strong>',],

             [ '*"foo"* and **!bar!**' => '<em>&quot;foo&quot;</em> and <strong>!bar!</strong>',],

             # opening inline wants something not a word before, and something not a space after.
             # closing inline wants something not a space before, and something not a word after.

             # Asterisk and equal symbols (<verbatim>*, **, ***
             # =</verbatim>) are interpreted as markup elements if
             # they are paired.

             # The opening one must be preceded by something which is
             # not a word (or at the beginning of the line) and
             # followed by something not which is not a space.

             # The closing one must be preceded by something which is
             # not a space, and followed by something which is not a
             # word (or at the end of the line).

             # Random unclear input gets an undefined behavior, for
             # that please use the tag versions (<verbatim><code>,
             # <em>, <strong>).

             [ '=$var $<=' => '<code>$var $&lt;</code>' ],
             [ '=$var *test* $<=' => '<code>$var *test* $&lt;</code>' ],
            );

my @contexts = ('', "/", " ", " material ", ",", ".", "(", "-");

plan tests => scalar(@tests) * scalar(@contexts);

foreach my $test (@tests) {
    my $opts = @$test > 2 ? $test->[2] : {};
    foreach my $add (@contexts) {
        my $html = muse_to_object($add . $test->[0] . $add)->as_html;
        $html =~ s/\n<p>\n//;
        $html =~ s/\n<\/p>\n//;
        my $expected = $add . $test->[1] . $add;
        $expected =~ s/\s*\z//;
      SKIP: {
            skip "${add}$test->[0]${add} => $html", 1 if $opts->{skip_adding} && $add;
            is $html, $expected, "'${add}$test->[0]${add}' => '$expected'";
        }
    }
}
