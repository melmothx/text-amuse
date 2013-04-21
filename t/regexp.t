use strict;
use warnings;
use Test::More;
use Text::AMuse;
use File::Spec::Functions;
use Data::Dumper;

my $document =
  Text::AMuse->new(file => catfile(t => testfiles => 'packing.muse'));

foreach my $url ("http://example.org",
                 "http://example.org/",
                 "http://example.org/my/path/hello.html",
                 'http://example.org/my/path/hello.html?q=234&b=234%sdf',
                 "http://example.org:23423",
                 "http://example.org:23423/",
                 "http://example.org/?q=234&b=asdlklfj#helllo") {
    ok($url =~ $document->url_re, "$url matches url");
    my $matched = $1;
    is($matched, $url, "$url is an url");
    foreach my $puct (")", ".", ";", "}", "]", " ", "\n") {
        my $string = $puct . $url . $puct;
        ok($string =~ $document->url_re, "$string matches");
        is($1, $url, "$url eq $1");
    }
}

done_testing;
