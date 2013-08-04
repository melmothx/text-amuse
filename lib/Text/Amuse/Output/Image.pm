package Text::Amuse::Output::Image;
use strict;
use warnings;
use utf8;
use Scalar::Util qw/looks_like_number/;

=head1 NAME

Text::Amuse::Output::Image -- class to manage images

=head1 SYNOPSIS

The module is used internally by L<Text::Amuse>, so everything here is
pretty much internal only (and underdocumented).

=head1 METHODS/ACCESSORS

=head2 new(filename => "hello.png", width => 0.5, wrap => 1)

Constructor. Accepts three options: filename, width, as a float, and
wrap, as a boolean. C<filename> is mandatory.

These arguments are saved in the objects and can be accessed with:

=over 4

=item filename

=item width

=item wrap

=back

=cut

sub new {
    my $class = shift;
    my $self = {
                    width => 1,
                    wrap => 0,
                   };
    my %opts = @_;

    if (my $f = $opts{filename}) {
        $self->{filename} = $f;
        # just to be sure
        unless ($f =~ m{^[0-9A-Za-z][0-9A-Za-z/-]+\.(png|jpe?g)}s) {
            die "Illegal filename $f!";
        }
    }
    else {
        die "Missing filename argument!";
    }

    if ($opts{wrap}) {
        $self->{wrap} = 1; 
    }

    if (my $w = $opts{width}) {
        if (looks_like_number($w)) {
            $self->{width} = sprintf('%.2f', $w);
        }
        else {
            die "Wrong width $w passed!";
        }
    }

    bless $self, $class;
}

sub width {
    return shift->{width};
}

sub wrap {
    return shift->{wrap};
}

sub filename {
    return shift->{filename};
}

=head2 Formatters

=over4

=item width_html

Width in percent

=item width_latex

Width as  '0.25\textwidth'

=cut

sub width_html {
    my $self = shift;
    my $width = $self->width;
    my $width_in_pc = sprintf('%d', $width * 100);
    return $width_in_pc . '%';
}

sub width_latex {
    my $self = shift;
    my $width = $self->width;
    if ($width == 1) {
        return "\\textwidth";
    }
    else {
        return $self->width . "\\textwidth"; # a float
    }
}

1;

