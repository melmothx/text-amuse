use strict;
use warnings;
use Data::Dumper;
use Text::Amuse;
use File::Spec::Functions;
use Test::More tests => 270;

foreach my $file (qw/secondary-fn footnotes-packing footnotes footnotes-2 br-in-footnotes footnotes-multiline/) {
    my $doc = Text::Amuse->new(file => catfile(qw/t testfiles/, "$file.muse"));
    my @htmls = $doc->as_splat_html;
    foreach my $html (@htmls) {
        my @refs;
        while ($html =~ m/href="#(fn.*?)"/g) {
            push @refs, $1
        }
        foreach my $ref (@refs) {
            like $html, qr{id="\Q$ref\E"}, "Found id $ref in $file";
        }
        @refs = ();
        my %dupes;
        while ($html =~ m/id="(fn.*?)"/g) {
            push @refs, $1;
            $dupes{$1}++;
        }
        foreach my $ref (@refs) {
            like $html, qr{href="#\Q$ref\E"}, "Found link to $ref in $file";
        }
        foreach my $id (keys %dupes) {
            is $dupes{$id}, 1, "No duplicate id for $id";
        }
    }
    # diag Dumper(\@htmls);
}
