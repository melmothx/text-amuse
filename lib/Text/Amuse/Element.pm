package Text::Amuse::Element;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Amuse::Element - Helper for Text::Amuse

=head1 METHODS/ACCESSORS

Everything here is pretty much internal only, underdocumented and
subject to change.

=over 4

=item new(%args)

Constructor

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {
                rawline => '',
                raw_without_anchors => '',
                block => '',      # the block it says to belong
                type => 'null', # the type
                string => '',      # the string
                removed => '', # the portion of the string removed
                attribute => '', # optional attribute for desclists
                indentation => 0,
                attribute_type => '',
                style => 'X',
                start_list_index => 0,
                element_number => 0,
                footnote_number => 0,
                footnote_symbol => '',
                footnote_index => '',
                anchors => [],
                language => '',
               };
    my %provided;
    foreach my $accessor (keys %$self) {
        if (exists $args{$accessor} and defined $args{$accessor}) {
            $self->{$accessor} = $args{$accessor};
            $provided{$accessor} = 1;
        }
    }
    unless ($provided{indentation}) {
        $self->{indentation} = length($self->{removed});
    }

    die "anchors passed to the constructor but not a reference $self->{anchors}"
      unless ref($self->{anchors}) eq 'ARRAY';

    if (exists $args{anchor} and length $args{anchor}) {
        push @{$self->{anchors}}, $args{anchor};
    }

    bless $self, $class;
}

=item language

Accessor to the language attribute

=cut

sub language {
    shift->{language};
}

=item rawline

Accessor to the raw input line

=cut

sub rawline {
    my $self = shift;
    return $self->{rawline};
}

=item raw_without_anchors

Return the original string, but with anchors stripped out.

=cut

sub raw_without_anchors {
    my $self = shift;
    return $self->{raw_without_anchors};
}

sub _reset_rawline {
    my ($self, $line) = @_;
    $self->{rawline} = $line;
}

=item will_not_merge

Attribute to mark if an element cannot be further merged

=cut

sub will_not_merge {
    my ($self, $arg) = @_;
    if (defined $arg) {
        $self->{_will_not_merge} = $arg;
    }
    return $self->{_will_not_merge};
}

=item anchors

A list of anchors for this element.

=item add_to_anchors(@list)

Add the anchors passed to the constructor to this element.

=item remove_anchors

Empty the anchors array in the element

=item move_anchors_to($element)

Remove the anchors from this element and add them to the one passed as
argument.

=cut

sub anchors {
    my $self = shift;
    return @{$self->{anchors}};
}

sub add_to_anchors {
    my ($self, @anchors) = @_;
    push @{$self->{anchors}}, @anchors;
}

sub remove_anchors {
    my ($self) = @_;
    $self->{anchors} = [];
}

sub move_anchors_to {
    my ($self, $el) = @_;
    $el->add_to_anchors($self->anchors);
    $self->remove_anchors;
}

=back

=head2 ACCESSORS

The following accessors set the value if an argument is provided. 

=over 4

=item block

The block the string belongs

=cut

sub block {
    my $self = shift;
    if (@_) {
        $self->{block} = shift;
    }
    return $self->{block} || $self->type;
}

=item type

The type

=cut

sub type {
    my $self = shift;
    if (@_) {
        $self->{type} = shift;
    }
    return $self->{type};
}

=item string

The string (without the indentation or the leading markup)

=cut

sub string {
    my $self = shift;
    if (@_) {
        $self->{string} = shift;
    }
    return $self->{string};
}

=item removed

The portion of the string stripped out

=cut

sub removed {
    my $self = shift;
    if (@_) {
        die "Read only attribute!";
    }
    return $self->{removed};
}

=item style

The block style. Default to C<X>, read only. Used for aliases of tags,
when closing it requires a matching style.

=cut

sub style {
    my $self = shift;
    die "Read only attribute!" if @_;
    return $self->{style};
}

=item indentation

The indentation level, as a numerical value

=cut

sub indentation {
    return shift->{indentation};
}

=item footnote_number

The footnote number

=cut

sub footnote_number {
    return shift->{footnote_number};
}

=item footnote_symbol

The footnote symbol

=cut

sub footnote_symbol {
    return shift->{footnote_symbol};
}

=item footnote_index

The footnote index

=cut

sub footnote_index {
    return shift->{footnote_index};
}




=item attribute

Accessor to attribute

=cut

sub attribute {
    return shift->{attribute};
}

=item attribute_type

Accessor to attribute_type

=cut

sub attribute_type {
    return shift->{attribute_type};
}


=item start_list_index

Accessor rw to start_list_index (defaults to 0)

=cut

sub start_list_index {
    my $self = shift;
    if (@_) {
        my $arg = shift;
        if (defined $arg) {
            $self->{start_list_index} = $arg;
        }
    }
    return $self->{start_list_index};
}

=back

=head2 HELPERS

=over 4

=item is_start_block($blockname)

Return true if the element is a "startblock" of the required block name

=cut

sub is_start_block {
    my $self = shift;
    my $block = shift || "";
    if ($self->type eq 'startblock' and $self->block eq $block) {
        return 1;
    } else {
        return 0;
    }
}

=item is_stop_element($element)

Return true if the element is a matching stopblock for the element
passed as argument.

=cut

sub is_stop_element {
    my ($self, $element) = @_;
    if ($element and
        $self->type eq 'stopblock' and
        $self->block eq $element->type and
        $self->style eq $element->style) {
        return 1;
    }
    else {
        return 0;
    }
}

=item is_regular_maybe

Return true if the element is "regular", i.e., it just have trailing
white space

=cut

sub is_regular_maybe {
    my $self = shift;
    if ($self->type eq 'li' or
        $self->type eq 'null' or
        $self->type eq 'regular') {
        return 1;
    } else {
        return 0;
    }
}

=item can_merge_next

Return true if the element will merge the next one

=cut

sub can_merge_next {
    my $self = shift;
    return 0 if $self->will_not_merge;
    my %nomerge = (
                   bidimarker    => 1,
                   stopblock     => 1,
                   startblock    => 1,
                   null          => 1,
                   table         => 1,
                   versep        => 1,
                   newpage       => 1,
                   inlinecomment => 1,
                   comment       => 1,
                  );
    if ($nomerge{$self->type}) {
        return 0;
    } else {
        return 1;
    }
}

=item can_be_merged

Return true if the element will merge the next one. Only regular strings.

=cut

sub can_be_merged {
    my $self = shift;
    return 0 if $self->will_not_merge;
    if ($self->type eq 'regular' or $self->type eq 'verse') {
        return 1;
    }
    else {
        return 0;
    }
}

=item can_be_in_list

Return true if the element can be inside a list

=cut

sub can_be_in_list {
    my $self = shift;
    if ($self->type eq 'li' or
        $self->type eq 'null', or
        $self->type eq 'regular') {
        return 1;
    } else {
        return 0;
    }
}

=item can_be_regular

Return true if the element is quote, center, right

=cut

sub can_be_regular {
    my $self = shift;
    return 0 unless $self->type eq 'regular';
    if ($self->block eq 'quote' or
        $self->block eq 'center' or
        $self->block eq 'right') {
        return 1;
    }
    else {
        return 0;
    }
}


=item should_close_blocks

=cut

sub should_close_blocks {
    my $self = shift;
    return 0 if $self->type eq 'regular';
    return 1 if $self->type =~ m/h[1-5]/;
    return 1 if $self->block eq 'example';
    return 1 if $self->block eq 'verse';
    return 1 if $self->block eq 'table';
    return 1 if $self->type eq 'newpage';
    return 0;
}


=item add_to_string($string, $other_string, [...])

Append (just concatenate) the given strings to the string attribute.

=cut

sub add_to_string {
    my ($self, @args) = @_;
    my $orig = $self->string;
    $self->_reset_rawline(); # we modify the string, so throw away the rawline
    $self->string(join("", $orig, @args));
}

=item append($element)

Append the element passed as argument to this one, setting the raw_line

=cut

sub append {
    my ($self, $element) = @_;
    $self->{rawline} .= $element->rawline;
    $self->{raw_without_anchors} .= $element->raw_without_anchors;
    my $type = $self->type;
    # greedy elements
    if ($type eq 'example') {
        $self->{string} .= $element->rawline;
        # ignore the anchors, they can't be inside.
        return;
    }
    elsif ($type eq 'verse' or $type eq 'footnote') {
        $self->{string} .= $element->raw_without_anchors;
    }
    else {
        $self->{string} .= $element->string;
    }
    # inherit the anchors
    $self->add_to_anchors($element->anchors);
}

=item can_append($element)

=cut

sub can_append {
    my ($self, $element) = @_;
    if ($self->can_merge_next && $element->can_be_merged) {
        return 1;
    }
    if ($self->type eq 'footnote' and
        $element->type ne 'footnote' and
        $element->type ne 'null' and
        !$element->should_close_blocks) {
        return 1;
    }
    # same type. Marked as can_merge_next => false
    foreach my $type (qw/table versep null/) {
        if ($self->type eq $type and $element->type eq $type) {
            return 1;
        }
    }
    return 0;
}

=item become_regular

Set block to empty string and type to regular

=cut

sub become_regular {
    my $self = shift;
    $self->type('regular');
    $self->block('');
}

=item element_number

Internal numbering of the element.

=cut

sub element_number {
    return shift->{element_number};
}

sub _set_element_number {
    my ($self, $num) = @_;
    $self->{element_number} = $num;
}

=item is_header

Return 1 if the element type is h1/h6, 0 otherwise.

=cut

sub is_header {
    my $self = shift;
    if ($self->type =~ m/h[1-6]/) {
        return 1;
    }
    else {
        return 0;
    }
}

=back

=cut

1;
