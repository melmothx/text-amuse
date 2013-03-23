package Text::AMuse::Element;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Muse::Element - Helper for Text::Muse

=head1 METHODS/ACCESSORS

=head3 new($string)

Constructor. Accepts a string to be parsed

=cut

sub new {
    my $class = shift;
    my $line = shift;
    die "Too many arguments, I accept only a single string" if @_;
    my $self = {
                rawline => $line,
                block => "",      # the block it says to belog
                type => "null", # the type
                string => "",      # the string
                removed => "", # the portion of the string removed
                indentation => 0, # the indentation as numerical value

               };
    bless $self, $class;
    # initialize it
    $self->_parse_string;
    return $self;
}

=head3 rawline

Accessor to the raw input line

=cut

sub rawline {
    my $self = shift;
    return $self->{rawline};
}

=head2 ACCESSORS

The following accessors set the value if an argument is provided. 

=head3 block

The block the string belongs

=cut

sub block {
    my $self = shift;
    if (@_) {
        $self->{block} = shift;
    }
    return $self->{block};
}

=head3 type

The type

=cut

sub type {
    my $self = shift;
    if (@_) {
        $self->{type} = shift;
    }
    return $self->{type};
}

=head3 string

The string (without the indentation or the leading markup)

=cut

sub string {
    my $self = shift;
    if (@_) {
        $self->{string} = shift;
    }
    return $self->{string};
}

=head3 removed

The portion of the string stripped out

=cut

sub removed {
    my $self = shift;
    if (@_) {
        $self->{removed} = shift;
    }
    return $self->{removed};
}

=head3 indentation

The indentation level, as a numerical value

=cut

sub indentation {
    my $self = shift;
    return length($self->removed);
}

sub _parse_string {
    my $self = shift;
    my $string = $self->rawline;
    $self->string($string);
}


1;
