package Text::Amuse::Functions;
use strict;
use warnings;
use utf8;
use Text::Amuse;
use Text::Amuse::String;
use Text::Amuse::Output;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw/muse_format_line
                   /;


# 
# sub muse_to_html {
#     return;
# }
# 
# sub muse_to_latex {
#     return;
# }
# 

=head3 muse_format_line ($format, $string)

Output the given chunk in the desired format (C<html> or C<ltx>).

This is meant to be used for headers, or for on the fly escaping. So
lists, footnotes, tables, blocks, etc. are not supported. Basically,
we process only one paragraph, without wrapping it in <p>.

=cut

sub muse_format_line {
    my ($format, $line) = @_;
    return "" unless defined $line;
    die unless ($format eq 'html' or $format eq 'ltx');
    my $doc = Text::Amuse::String->new($line);
    my $out = Text::Amuse::Output->new(document => $doc,
                                       format => $format);
    return join("", @{ $out->process });
}
