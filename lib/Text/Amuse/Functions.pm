package Text::Amuse::Functions;
use strict;
use warnings;
use utf8;
use File::Temp;
use File::Copy qw/move/;
use Text::Amuse;
use Text::Amuse::String;
use Text::Amuse::Output;
use Text::Amuse::Document;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw/muse_format_line
                    muse_fast_scan_header
                    muse_to_html
                    muse_to_tex
                    muse_to_object
                    muse_rewrite_header
                   /;


=head1 NAME

Text::Amuse::Functions - Exportable functions for L<Text::Amuse>

=head1 SYNOPSIS

This module provides some functions to format strings wrapping the OO
interface to function calls.

  use Text::Amuse::Functions qw/muse_format_line/
  my $html = muse_format_line(html => "hello 'world'");
  my $ltx =  muse_format_line(ltx => "hello #world");

=head1 FUNCTIONS

=over 4

=item muse_format_line ($format, $string, [ $lang ])

Output the given chunk in the desired format (C<html> or C<ltx>).

Accepts a third parameter with the language code. This is usually not
needed unless you're dealing with French.

This is meant to be used for headers, or for on the fly escaping. So
lists, footnotes, tables, blocks, etc. are not supported. Basically,
we process only one paragraph, without wrapping it in <p>.

=cut

sub muse_format_line {
    my ($format, $line, $lang) = @_;
    return "" unless defined $line;
    die unless ($format eq 'html' or $format eq 'ltx');
    my $doc = Text::Amuse::String->new($line, $lang);
    my $out = Text::Amuse::Output->new(document => $doc,
                                       format => $format);
    return join("", @{ $out->process });
}

=item muse_fast_scan_header($file, $format);

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
    my $doc = Text::Amuse::Document->new(file => $file);
    my $directives = $doc->parse_directives;

    if ($format) {
        die "Wrong format $format"
          unless ($format eq 'ltx' or $format eq 'html');
        foreach my $k (keys %$directives) {
            $directives->{$k} = muse_format_line($format, $directives->{$k}, $doc->language_code);
        }
    }
    return $directives;
}

=item muse_to_html($body);

Format the $body text (assumed to be decoded) as HTML and return it.
Header is discarded.

$body can also be a reference to a scalar to speed up the argument
passing.

=item muse_to_tex($body);

Format the $body text (assumed to be decoded) as LaTeX and return it.
Header is discarded

$body can also be a reference to a scalar to speed up the argument
passing.

=item muse_to_object($body);

Same as above, but returns the L<Text::Amuse> document instead.

=cut

sub muse_to_html {
    return _format_on_the_fly(html => @_);
}

sub muse_to_tex {
    return _format_on_the_fly(ltx => @_);
}

sub muse_to_object {
    return _format_on_the_fly(obj => @_);
}

sub _format_on_the_fly {
    my ($format, $text, $opts) = @_;
    my %opt;
    if ($opts and ref($opts) eq 'HASH') {
        %opt = %$opts;
    }
    my $fh = File::Temp->new(SUFFIX => '.muse');
    binmode $fh, ':encoding(utf-8)';
    if (ref $text) {
        print $fh $$text, "\n";
    }
    else {
        print $fh $text, "\n";
    }
    # flush the file and close it
    close $fh;
    my $doc = Text::Amuse->new(%opt, file => $fh->filename);
    if ($format eq 'ltx') {
        return $doc->as_latex;
    }
    elsif ($format eq 'html') {
        return $doc->as_html;
    }
    elsif ($format eq 'obj') {
        # dirty trick
        $doc->{_private_temp_fh} = $fh;
        return $doc;
    }
    else {
        die "Wrong usage, format can be only ltx or html!";
    }
}

=item muse_rewrite_header($file, { header1 => value, header2 => value2 })

Rewrite the headers of the given file, adding/replacing the header
where appropriate.

=cut

sub muse_rewrite_header {
    my ($file, $pairs) = @_;
    my $doc = Text::Amuse::Document->new(file => $file);
    # do a deep copy
    my @directives = map { [ @{$_} ] } $doc->directives_array;

  REWRITE:
    foreach my $key (keys %$pairs) {
        my $value = defined $pairs->{$key} ? $pairs->{$key} . "\n" : "\n";
      SEARCH:
        foreach my $dir (@directives) {
            if ($dir->[0] eq $key) {
                $dir->[1] = $value;
                next REWRITE;
            }
        }
        push @directives, [ $key, $value ];
    }
    my @out;
    foreach my $dir (@directives) {
        push @out, '#' . $dir->[0] . " " . $dir->[1];
    }
    my $now = time();
    my $rewritten = $file . '~rw' . $now;
    my $backup = $file . '~bk' . $now;
    open (my $fh, ">:encoding(UTF-8)", $rewritten);
    print $fh @out, "\n", $doc->raw_body;
    close $fh;
    move($file, $backup) or die "Cannot move $file into $backup $!";
    move($rewritten, $file) or die "Cannot move $rewritten into $backup $!";
}

=back

=cut

1;

