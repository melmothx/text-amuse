package Text::Amuse::String;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Amuse::String

=head1 SYNOPSIS

This module provies a minimal class compatible with
Text::Amuse::Document to process single strings passed via value.

=cut

=head3 new ($string);

Constructor

=cut

sub new {
    my ($class, $string) = @_;
    my $self;
    $self->{_raw_string} = $string;
    bless $self, $class;
    return $self;
};

=head3 string

The string stored

=cut

sub string {
    return shift->{_raw_string};
}

=head3 document

It returns the only L<Text::Amuse::Element> which composes the body.

=cut


sub document {
    my $self = shift;
    my $el = Text::Amuse::Element->new($self->string);

    # restore the mangling;
    my $string = $el->string;
    my $removed = $el->removed;
    $el->string($removed . $string);
    $el->removed("");
    $el->type("standalone");
    return $el;
}

=head2 Fake methods

They return nothing, but nevertheless the Output module won't complain.

=over 4

=item raw_header

=item get_footnote

=item attachments

=back

=cut


sub raw_header {
    return;
}

sub get_footnote {
    return;
}

sub attachments {
    return;
}


1;
