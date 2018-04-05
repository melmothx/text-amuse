package Text::Amuse::Document::Block;
use strict;
use warnings;
use utf8;
use Scalar::Util qw/weaken/;

=head1 NAME

Text::Amuse::Document::Block - Block elements

=head1 METHODS/ACCESSORS

Everything here is pretty much internal only, underdocumented and
subject to change.

=head2 new(%args)

Constructor. Accepts the following named arguments (which are also
accessors)

=over 4

=item type

=back

=head2 children

Return a plain list of C<Text::Amuse::Document::Block> objects.

=head2 add_to_children(@elements)

Add the elements passed as argument to the element's children and set
their parent.

=head2 spawn(%args)

Call C<new> with the argument passed, add it to the children, and
return the newly created element.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {
                type => $args{type},
                parent => $args{parent},
                children => [],
                string => '',
               };
    weaken($self->{parent}) if $self->{parent};
    bless $self, $class;
}

sub type {
    return shift->{type};
}

sub children {
    return @{shift->{children}};
}

sub add_to_children {
    my ($self, @children) = @_;
    foreach my $child (@children) {
        die "Not a block" unless $child->isa('Text::Amuse::Document::Block');
        $child->set_parent($self);
        push @{$self->{children}}, $child;
    }
}

sub parent {
    return shift->{parent};
}

sub set_parent {
    my ($self, $parent) = @_;
    if (defined $parent and $parent->isa('Text::Amuse::Document::Block')) {
        $self->{parent} = $parent;
        weaken($self->{parent});
    }
    else {
        $self->{parent} = undef;
    }
}

sub spawn {
    my ($self, %args) = @_;
    my $block = __PACKAGE__->new(%args);
    $self->add_to_children($block);
    die "Parent not set?" unless $block->parent;
    die "Parent is not weak" unless Scalar::Util::isweak($block->{parent});
    return $block;
}

sub root {
    my $self = shift;
    if ($self->parent) {
        return $self->parent->root;
    }
    else {
        return $self;
    }
}
           

1;
