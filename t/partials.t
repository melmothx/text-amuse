#!perl

use strict;
use warnings;
use utf8;
use Test::More;
use Text::Amuse;
use File::Temp;
use Data::Dumper;

my $muse = <<'MUSE';
#title The title
#author The author

First chunk (0)

* First part (1)

First part body (1)

** First chapter (2)

First chapter body (2)

*** First section (3)

First section body (3)

**** First subsection (4)

First subsection (4)

 Item :: Blabla (4)

* Second part (5)

Second part body (5)

** Second chapter (6)

Second chapter body (6)

*** Second section (7)

Second section body (7)

**** Second subsection (8)

Second subsection (8)

 Item :: Blabla

*** Third section (9)

Third section (9)

 Item :: Blabla

*** Fourth section (10)

Blabla (10)

MUSE

my $fh = File::Temp->new(SUFFIX => '.muse');
binmode $fh, ':encoding(utf-8)';
print $fh $muse;
close $fh;

{
    my $doc = eval { Text::Amuse->new(file => $fh->filename, partial => 'bla') };
    ok ($@, "Found exception $@");
}

{
    my $doc = eval { Text::Amuse->new(file => $fh->filename,
                                      partial => { bla => 1 }) };
    ok ($@, "Found exception $@");
}

{
    my $doc = eval { Text::Amuse->new(file => $fh->filename,
                                      partial => [qw/a b/]) };
    ok ($@, "Found exception $@");
}

{
    my $doc = eval { Text::Amuse->new(file => $fh->filename,
                                      partial => [qw/1 3 9 100/]) };
    ok (!$@, "doc created") or diag $@;
    ok $doc;
    is_deeply($doc->partials, { 1 => 1, 3 => 1, 9 => 1, 100 => 1 }, "Partials are good");
    foreach my $method (qw/as_splat_html as_splat_latex/) {
        my @chunks = $doc->$method;
        is (scalar(@chunks), 3, "Found 3 chunks");
        like ($chunks[0], qr{\(1\).*\(1\)}s);
        like ($chunks[1], qr{\(3\).*\(3\)}s);
        like ($chunks[2], qr{\(9\).*\(9\)}s);
    }
    foreach my $method (qw/as_html as_latex/) {
        my $body = $doc->$method;
        like $body, qr{\(1\).*\(1\).*\(3\).*\(3\).*\(9\).*\(9\)}s, "$method ok with keys";
        unlike $body, qr{\([2456780]+\)}, "full $method without excluded kes ok";
    }
}

done_testing;
