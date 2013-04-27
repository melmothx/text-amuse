package t::Utils;
use strict;
use warnings;
use utf8;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/write_to_file
                    read_file/;


sub write_to_file {
    my ($file, @stuff);
    open (my $fh, ">:encoding(utf-8)", $file) or die "Couldn't open $file $!";
    print $fh @stuff;
    close $fh;
}

sub read_file {
    my $file = shift;
    local $/ = undef;
    open (my $fh, "<:encoding(utf-8)", $file) or die "Couldn't open $file $!";
    my $string = <$fh>;
    close $fh;
    return $string;
}


1;
