use strict;
use warnings;
use utf8;
use Test::More;
use Text::Amuse::Output::Image;

plan tests => 11;
my $image;
$image = Text::Amuse::Output::Image->new(
                                         width => 0.25,
                                         wrap => "r",
                                         filename => "test.png",
                                        );

ok($image->wrap, "wrap ok");
is($image->width, "0.25", "width ok");
is($image->width_html, "25%", "html width ok");
is($image->width_latex, "0.25\\textwidth", "LaTeX width ok");

$image = Text::Amuse::Output::Image->new(
                                         filename => "test.png",
                                        );

ok(!$image->wrap, "no wrap ok");
is($image->width, "1", "width ok");
is($image->width_html, "100%", "html width ok");
is($image->width_latex, "\\textwidth", "LaTeX width ok");

eval {
    $image = Text::Amuse::Output::Image->new(
                                             filename => "testù.png",
                                            );
};
ok($@, "Exception raised with illegal filename: $@");
eval {
    $image = Text::Amuse::Output::Image->new(
                                             filename => "test.pdf",
                                            );
};
ok($@, "Exception raised with wrong extension: $@");

eval {
    $image = Text::Amuse::Output::Image->new(
                                             filename => "test.jpeg",
                                             width => "abc",
                                            );
};
ok($@, "Exception raised with wrong width: $@");



