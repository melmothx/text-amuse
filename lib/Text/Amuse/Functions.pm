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
                    muse_fast_scan_header
                   /;


=head1 NAME

Text::Amuse::Functions

=head1 SYNOPSIS

This module provides some functions to format strings wrapping the OO
interface to function calls.

  use Text::Amuse::Functions qw/muse_format_line/
  my $html = muse_format_line(html => "hello 'world'");
  my $ltx =  muse_format_line(ltx => "hello #world");

=head1 FUNCTIONS

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

=head2 muse_fast_scan_header($file, $format);

Open the file $file, which is supposed to be UTF-8 encoded. Decode the
content and read its Muse header.

Returns an hash reference with the metadata.

If the second argument is set and is C<ltx> or <html>, filter the
hashref values through C<muse_format_line>.

It dies if the file doesn't exist or can't be read.

=cut

sub muse_fast_scan_header {
    my ($file, $format) = @_;
    die "No file provided!" unless defined($file) && length($file);
    die "$file is not a file!" unless -f $file;
    open (my $fh, "<:encoding(UTF-8)", $file) or die "Can't read file $!\n";
    my %directives;
    my $in_meta = 1;
    my $lastdirective;
    while (<$fh>) {
        my $line = $_;
        if ($in_meta) {
            # reset the directives on blank lines
            if ($line =~ m/^\s*$/s) {
                $lastdirective = undef;
            }

            elsif ($line =~ m/^\#([A-Za-z0-9]+)\s+(.+)$/s) {
                my $dir = $1;
                warn "Overwriting directive $dir!" if $directives{$dir};
                $directives{$dir} = $2;
                $lastdirective = $dir;
            }

            elsif ($lastdirective) {
                $directives{$lastdirective} .= $line;

            }
            else {
                $in_meta = 0
            }
        }
        last unless $in_meta;
    }
    close $fh;
    foreach my $k (keys %directives) {
        $directives{$k} =~ s/\s+/ /gs;
        $directives{$k} =~ s/^\s+//s;
        $directives{$k} =~ s/\s+$//s;
    }
    if ($format) {
        die "Wrong format $format"
          unless ($format eq 'ltx' or $format eq 'html');
        foreach my $k (keys %directives) {
            $directives{$k} = muse_format_line($format, $directives{$k});
        }
    }
    return \%directives;
}


1;

