#!perl

use strict;
use warnings;

use Text::Amuse;
use Text::Amuse::Functions qw/muse_to_object/;
use Data::Dumper;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 7;
use File::Temp;

my $doc =
  Text::Amuse->new(file => catfile(t => testfiles => 'beamer.muse'),
                   debug => 0);

my $body = $doc->as_beamer;
ok($body, "beamer body produced");
unlike($body, qr/ignore/, "Ignored parts are ignored");
like($body, qr/Subsubsection.*This.*is.*the.*list/s, "Found the first list");
like ($doc->as_beamer, qr/\\begin\{frame\}\[fragile\]/,
      "Found a frame");
like ($doc->as_beamer, qr/\\end\{frame\}/,
      "Found a frame");
$doc = muse_to_object("#title Test\n\nblablabla\n\nbalbal\n");
ok ($doc->as_latex, "LaTeX output ok");
is ('', $doc->as_beamer, "beamer yields an empty string when there is no section");


sub write_to_file {
    my ($file, @stuff) = @_;
    open (my $fh, ">:encoding(utf-8)", $file) or die "Couldn't open $file $!";
    print $fh @stuff;
    close $fh;
}
