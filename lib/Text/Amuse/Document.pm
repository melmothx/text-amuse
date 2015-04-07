package Text::Amuse::Document;

use 5.010001;
use strict;
use warnings;
use Text::Amuse::Element;
# use Data::Dumper;

=head1 NAME

Text::Amuse::Document

=head1 SYNOPSIS

The module is used internally by L<Text::Amuse>, so everything here is
pretty much internal only (and underdocumented). The useful stuff is
accessible via the L<Text::Amuse> class.

=head1 METHODS

=head3 new(file => $filename)

=cut

sub new {
    my $class = shift;
    my %args;
    my $self = {};
    if (@_ % 2 == 0) {
        %args = @_;
    }
    elsif (@_ == 1) {
        $args{file} = shift;
    }
    else {
        die "Wrong arguments! The constructor accepts only a filename\n";
    }
    if (-f $args{file}) {
        $self->{filename} = $args{file};
    } else {
        die "Wrong argument! $args{file} doesn't exist!\n"
    }
    $self->{debug} = 1 if $args{debug};
    bless $self, $class;
}


sub _debug {
    my $self = shift;
    my @args = @_;
    if ((@args) && $self->{debug}) {
        print join("\n", @args), "\n";
    }
}


=head3 filename

Return the filename of the processed file

=cut

sub filename {
    my $self = shift;
    return $self->{filename}
}

=head3 attachments

Return the list of the filenames of the attached files, as linked.
With an optional argument, store that file in the list.


=cut

sub attachments {
    my ($self, $arg) = @_;
    unless (defined $self->{_attached_files}) {
        $self->{_attached_files} = {};
    }
    if (defined $arg) {
        $self->{_attached_files}->{$arg} = 1;
        return;
    }
    else {
        return sort(keys %{$self->{_attached_files}});
    }
}


=head3 get_lines

Returns the raw input lines as a list, reading from the filename if
it's the first time we call it. Tabs, \r and trailing whitespace are
cleaned up.

=cut

sub get_lines {
    my $self = shift;
    my $file = $self->filename;
    $self->_debug("Reading $file");
    open (my $fh, "<:encoding(utf-8)", $file) or die "Couldn't open $file! $!\n";
    my @lines;
    while (<$fh>) {
        my $l = $_;
        # EOL
        $l =~ s/\r\n/\n/gs;
        $l =~ s/\r/\n/gs;
        # TAB
        $l =~ s/\t/    /g;
        # trailing
        $l =~ s/ +$//mg;
        push @lines, $l;
    }
    close $fh;
    # store the lines in the object
    return \@lines;
}


sub _split_body_and_directives {
    my $self = shift;
    my (%directives, @body);
    my $in_meta = 1;
    my $lastdirective;
    my $input = $self->get_lines;
    # scan the line
    while (@$input) {
        my $line = shift @$input;
        if ($in_meta) {
            # reset the directives on blank lines
            if ($line =~ m/^\s*$/s) {
                $lastdirective = undef;
            } elsif ($line =~ m/^\#([A-Za-z0-9]+)(\s+(.+))?$/s) {
                my $dir = $1;
                if ($2) {
                    $directives{$dir} = $3;
                }
                else {
                    $directives{$dir} = '';
                }
                $lastdirective = $dir;
            } elsif ($lastdirective) {
                $directives{$lastdirective} .= $line;
            } else {
                $in_meta = 0
            }
        }
        next if $in_meta;
        push @body, $line;
    }
    push @body, "\n"; # append a newline
    # before returning, let's clean the %directives from EOLs
    foreach my $key (keys %directives) {
        $directives{$key} =~ s/\s/ /gs;
        $directives{$key} =~ s/\s+$//gs;
    }
    $self->{raw_body}   = \@body;
    $self->{raw_header} = \%directives;
}

=head3 raw_header

Accessor to the raw header of the muse file. The header is returned as
hash, with key/value pairs. Please note: NOT an hashref.

=cut

sub raw_header {
    my $self = shift;
    unless (defined $self->{raw_header}) {
        $self->_split_body_and_directives;
    }
    return %{$self->{raw_header}}
}

=head3 raw_body

Accessor to the raw body of the muse file. The body is returned as a
list of lines.

=cut

sub raw_body {
    my $self = shift;
    unless (defined $self->{raw_body}) {
        $self->_split_body_and_directives;
    }
    return @{$self->{raw_body}}
}

sub _parse_body {
    my $self = shift;
    $self->_debug("Parsing body");

    # be sure to start with a null block and reset the state
    my @parsed = ($self->_construct_element(""));
    $self->_current_el(undef);

    foreach my $l ($self->raw_body) {
        # if doesn't return anything, the thing got merged
        if (my $el = $self->_construct_element($l)) {
            push @parsed, $el;
        }
    }
    # turn the versep into verse now that the merging is done
    foreach my $el (@parsed) {
        if ($el->type eq 'versep') {
            $el->type('verse');
        }
    }
    my @out;
    my @listpile;
  LISTP:
    while (@parsed) {
        my $el = shift @parsed;
        # li, null or regular
        if ($el->type eq 'li') {
            if (@listpile) {
                # same indentation, continue
                if ($el->indentation == $listpile[$#listpile]->indentation) {
                    my ($open, $close) = $self->_create_block_pair(li => $el->indentation);
                    push @out, $close, $open;
                }

                # indentation is major, open a new level
                elsif ($el->indentation > $listpile[$#listpile]->indentation) {
                    my ($open, $openli, $closeli, $close) = $self->_create_blocks_for_new_level($el);
                    push @out, $open, $openli;
                    push @listpile, $close, $closeli;
                }

                # indentation is minor, pop the pile until we reach the level
                elsif ($el->indentation < $listpile[$#listpile]->indentation) {
                    # close the lists until we get the the right level
                    while(@listpile and $el->indentation < $listpile[$#listpile]->indentation) {
                        push @out, pop @listpile;
                    }
                    # continue if open
                    if (@listpile) {
                        my ($openli, $closeli) = $self->_create_block_pair(li => $el->indentation);
                        push @out, $closeli, $openli;
                    }
                    # if by chance, we emptied all, start anew.
                    else {
                        my ($open, $openli, $closeli, $close) = $self->_create_blocks_for_new_level($el);
                        push @out, $open, $openli;
                        push @listpile, $close, $closeli;
                    }
                }
                else {
                    die "Not reached";
                }
            }
            # no list pile, this is the first element
            else {
                my ($open, $openli, $closeli, $close) = $self->_create_blocks_for_new_level($el);
                push @out, $open, $openli;
                push @listpile, $close, $closeli;
            }
            $el->type('regular'); # flip the type to regular
            $el->block('');
        }
        elsif ($el->type eq 'regular') {
            # the type is regular: It can only close or continue
            while (@listpile and $el->indentation < $listpile[$#listpile]->indentation) {
                push @out, pop @listpile;
            }
            if (@listpile) {
                $el->type('regular'); # flip the type to regular if in list
                $el->block('');
            }
        }
        push @out, $el;
    }
    # end of input?
    while (@listpile) {
        push @out, pop @listpile;
    }

    # now we use parsed as output
    my %footnotes;
    while (@out) {
        my $el = shift @out;
        if ($el->type eq 'footnote') {
            if ($el->removed =~ m/\[([0-9]+)\]/) {
                warn "Overwriting footnote number $1" if exists $footnotes{$1};
                $footnotes{$1} = $el;
            }
            else { die "Something is wrong here! <" . $el->removed . ">"
                     . $el->string . "!" }
        }
        else {
            push @parsed, $el;
        }
    }
    $self->_raw_footnotes(\%footnotes);

    # unroll the quote/center/right blocks
    while (@parsed) {
        my $el = shift @parsed;
        if ($el->can_be_regular) {
            my ($open, $close) = $self->_create_block_pair($el->block,
                                                           $el->indentation);
            $el->block("");
            push @out, $open, $el, $close;
        }
        else {
            push @out, $el;
        }
    }

    my @pile;
    while (@out) {
        my $el = shift @out;
        if ($el->type eq 'startblock') {
            push @pile, $self->_create_closing_block($el);
            $self->_debug("Pushing " . $el->block);
            die "Uh?\n" unless $el->block;
        }
        elsif ($el->type eq 'stopblock') {
            my $exp = pop @pile;
            unless ($exp and $exp->block eq $el->block) {
                warn "Couldn't retrieve " . $el->block . " from the pile\n";
                # put it back
                push @pile, $exp if $exp;
                # so what to do here? just removed it
                next;
            }
        }
        elsif (@pile and $el->should_close_blocks) {
            while (@pile) {
                my $block = pop @pile;
                warn "Forcing the closing of " . $block->block . "\n";
                push @parsed, $block;
            }
        }
        push @parsed, $el;
    }
    # do we still have things into the pile?
    while (@pile) {
        push @parsed, pop @pile;
    }
    return \@parsed;
}

=head2 elements

Return the list of the elements which compose the body, once they have
properly parsed and packed. Footnotes are removed. (To get the
footnotes use the accessor below).

=cut

sub elements {
    my $self = shift;
    unless (defined $self->{_parsed_document}) {
        # then store the footnotes
        # $self->_store_footnotes;

        # last run to check if we don't miss anything and remove the nulls
        # $self->_remove_nulls;
        $self->{_parsed_document} = $self->_parse_body;
    }
    return @{$self->{_parsed_document}}
}

=head3 get_footnote

Accessor to the internal footnotes hash. You can access the footnote
with a numerical argument or even with a string like [123]

=cut

sub get_footnote {
    my ($self, $arg) = @_;
    return undef unless $arg;
    # ignore the brackets, if they are passed
    if ($arg =~ m/([0-9]+)/) {
        $arg = $1;
    }
    else {
        return undef;
    }
    if (exists $self->_raw_footnotes->{$arg}) {
        return $self->_raw_footnotes->{$arg};
    }
    else { return undef }
}


sub _raw_footnotes {
    my $self = shift;
    if (@_) {
        $self->{_raw_footnotes} = shift;
    }
    return $self->{_raw_footnotes};
}

sub _parse_string {
    my ($self, $l, %opts) = @_;
    die unless defined $l;
    my %element = (
                   rawline => $l,
                  );
    my $blockre = qr{(
                         biblio   |
                         play     |
                         comment  |
                         verse    |
                         center   |
                         right    |
                         example  |
                         quote
                     )}x;
    
    # null line is default, do nothing
    if ($l =~ m/^[\n\t ]*$/s) {
        # do nothing, already default
        $element{removed} = $l;
        return %element;
    }
    if ($l =~ m!^(<($blockre)>\s*)$!s) {
        $element{type} = "startblock";
        $element{removed} = $1;
        $element{block} = $2;
        return %element;
    }
    if ($l =~ m!^(</($blockre)>\s*)$!s) {
        $element{type} = "stopblock";
        $element{removed} = $1;
        $element{block} = $2;
        return %element;
    }
    # headers
    if ($l =~ m!^((\*{1,5}) )(.+)$!s) {
        $element{type} = "h" . length($2);
        $element{removed} = $1;
        $element{string} = $3;
        return %element;
    }
    if ($l =~ m/^( +\- +)(.*)/s) {
        $element{type} = "li";
        $element{removed} = $1;
        $element{string} = $2;
        $element{block} = "ul";
        return %element;
    }
    if (!$opts{nolist}) {
        if ($l =~ m/^((\s+)  # leading space and type $1
                        (  # the type               $2
                            [0-9]+   |
                            [a-hA-H] |
                            [ixvIXV]+  |
                        )     
                        \. # a single dot
                        \s+)  # space
                    (.*) # the string itself $3
                   /sx) {
            my ($remove, $whitespace, $prefix, $text) = ($1, $2, $3, $4);
            my $indent = length($whitespace);
            $element{type} = "li";
            $element{removed} = $remove;
            $element{string} = $text;
            my $list_type = $self->_identify_list_type($prefix);
            $element{block} = $list_type;
            return %element;
        }
    }
    if ($l =~ m/^(\> )(.*)/s) {
        $element{string} = $2;
        $element{removed} = $1;
        $element{type} = "versep";
        return %element;
    }
    if ($l =~ m/^(\>)$/s) {
        $element{string} = "\n";
        $element{removed} = ">";
        $element{type} = "versep";
        return %element;
    }
    if ($l =~ m/^(\s+)/ and $l =~ m/\|/) {
        $element{type} = "table";
        $element{string} = $l;
        return %element;
    }
    if ($l =~ m/^(\; (.+))$/s) {
        $element{removed} = $l;
        $element{type} = "comment";
        return %element;
    }
    if ($l =~ m/^((\[[0-9]+\])\s+)(.+)$/s) {
        $element{type} = "footnote";
        $element{string} = $3;
        $element{removed} = $1;
        return %element;
    }
    if ($l =~ m/^((\s{6,})((\*\s?){5})\s*)$/s) {
        $element{type} = "newpage";
        $element{removed} = $2;
        $element{string} = $3;
        return %element;
    }
    if ($l =~ m/^( {20,})([^ ].+)$/s) {
        $element{block} = "right";
        $element{type} = "regular";
        $element{removed} = $1;
        $element{string} = $2;
        return %element;
    }
    if ($l =~ m/^( {6,})([^ ].+)$/s) {
        $element{block} = "center";
        $element{type} = "regular";
        $element{removed} = $1;
        $element{string} = $2;
        return %element;
    }
    if ($l =~ m/^( {2,})([^ ].+)$/s) {
        $element{block} = "quote";
        $element{type} = "regular";
        $element{removed} = $1;
        $element{string} = $2;
        return %element;
    }
    # anything else is regular
    $element{type} = "regular";
    $element{string} = $l;
    return %element;
}


sub _identify_list_type {
    my ($self, $list_type) = @_;
    my $type;
    if ($list_type =~ m/[0-9]/) {
        $type = "oln";
    } elsif ($list_type =~ m/[a-h]/) {
        $type = "ola";
    } elsif ($list_type =~ m/[A-H]/) {
        $type = "olA";
    } elsif ($list_type =~ m/[ixvl]/) {
        $type = "oli";
    } elsif ($list_type =~ m/[IXVL]/) {
        $type = "olI";
    } else {
        die "$type Unrecognized, fix your code\n";
    }
    return $type;
}

sub _current_el {
    my $self = shift;
    if (@_) {
        $self->{_current_el} = shift;
    }
    return $self->{_current_el};
}

sub _construct_element {
    my ($self, $line) = @_;
    my $current = $self->_current_el;
    my %args = $self->_parse_string($line);
    my $element = Text::Amuse::Element->new(%args);

    # catch the examples. and the verse
    # <example> is greedy, and will stop only at another </example> or
    # at the end of input.

    foreach my $block (qw/example verse/) {
        if ($current && $current->type eq $block) {
            if ($element->is_stop_block($block)) {
                $self->_current_el(undef);
                return Text::Amuse::Element->new(type => 'null',
                                                 removed => $element->rawline,
                                                 rawline => $element->rawline);
            }
            else {
                # maybe check if we want to stop at headings if verse?
                $current->append($element);
                return;
            }
        }
        elsif ($element->is_start_block($block)) {
            $current = Text::Amuse::Element->new(type => $block,
                                                 removed => $element->rawline,
                                                 rawline => $element->rawline);
            $self->_current_el($current);
            return $current;
        }
    }

    # Pack the lines
    if ($current && $current->can_append($element)) {
        $current->append($element);
        return;
    }

    $self->_current_el($element);
    return $element;
    
}

sub _create_block {
    my ($self, $open_close, $block, $indentation) = @_;
    die unless $open_close && $block;
    my $type;
    if ($open_close eq 'open') {
        $type = 'startblock';
    }
    elsif ($open_close eq 'close') {
        $type = 'stopblock';
    }
    else {
        die "$open_close is not a valid op";
    }
    my $removed = '';
    if ($indentation) {
        $removed = ' ' x $indentation;
    }
    return Text::Amuse::Element->new(block => $block,
                                     type => $type,
                                     removed => $removed);
}

sub _create_closing_block {
    my ($self, $el) = @_;
    return $self->_create_block(close => $el->block,
                                $el->indentation);
}

sub _create_block_pair {
    my ($self, $type, $indent) = @_;
    my $open = $self->_create_block(open => $type, $indent);
    my $close = $self->_create_closing_block($open);
    return ($open, $close);
}

sub _create_blocks_for_new_level {
    my ($self, $el) = @_;
    my ($open, $close) = $self->_create_block_pair($el->block, $el->indentation);
    my ($openli, $closeli) = $self->_create_block_pair(li => $el->indentation);
    return ($open, $openli, $closeli, $close);
}


1;
