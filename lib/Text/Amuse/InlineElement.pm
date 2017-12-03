package Text::Amuse::InlineElement;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Amuse::InlineElement - Helper for Text::Amuse

=head1 METHODS/ACCESSORS

Everything here is pretty much internal only, underdocumented and
subject to change.

=head3 new(%args)

Constructor

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {
                type => '',
                string => '',
                last_position => 0,
                tag => '',
                tag_name => '',
               };
    foreach my $k (keys %$self) {
        if (defined $args{$k}) {
            $self->{$k} = $args{$k};
        }
    }
    die "Missing type for <$self->{string}>" unless $self->{type};
    bless $self, $class;
}

sub type {
    shift->{type};
}

sub last_position {
    shift->{last_position};
}

sub string {
    shift->{string};
}

sub tag {
    shift->{tag};
}

sub tag_name {
    shift->{tag_name};
}

1;
