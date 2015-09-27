package Text::Amuse::Beamer;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Amuse::Beamer

=head1 DESCRIPTION

Parse the L<Text::Amuse::Output> LaTeX result and convert it to a
beamer documentclass body, wrapping the text into frames.

=head1 SYNOPSIS

The module is used internally by L<Text::Amuse>, so everything here is
pretty much internal only (and underdocumented).

=head1 METHODS

=head2 new(latex => \@latex_chunks)

=head2 latex

Accessor to the latex arrayref passed at the constructor.

=head2 process

Return the beamer body as a string.

=cut

sub new {
    my ($class, %args) = @_;
    die "Missing latex" unless $args{latex};
    my $self = { latex => [ @{$args{latex}} ] };
    bless $self, $class;
}

sub latex {
    return shift->{latex};
}

sub process {
    my $self = shift;
    my $out = '';
    return $out;
}

1;
