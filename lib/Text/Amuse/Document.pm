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

=head2 parsed_body (internal, but documented)

Accessor to the list of parsed lines. Each line will come as a
L<Text::Amuse::Element> object

The first block is guaranteed to be a null block

=cut

sub parsed_body {
    my $self = shift;
    if (@_) {
        $self->{parsed_body} = shift;
    }
    return @{$self->{parsed_body}} if defined $self->{parsed_body};
    $self->_debug("Parsing body");
    # be sure to start with a null block
    my @parsed = (Text::Amuse::Element->new("")); 
    foreach my $l ($self->raw_body) {
        push @parsed, Text::Amuse::Element->new($l);
    }
    $self->{parsed_body} = \@parsed;
    return @{$self->{parsed_body}};
}

=head2 document

Return the list of the elements which compose the body, once they have
properly parsed and packed. Nulls and footnotes are removed. (To get
the footnotes use the accessor below).

=cut

sub document {
    my $self = shift;
    unless (defined $self->{_parsed_document}) {
        # order matters!
        # pack the examples
        $self->_catch_example;

        # pack the verses
        $self->_catch_verse;

        # then pack the lines
        $self->_pack_lines;

        # then process the lists, using the indentation
        $self->_process_lists;

        # then unroll the blocks
        $self->_unroll_blocks;

        # then store the footnotes
        $self->_store_footnotes;

        # last run to check if we don't miss anything and remove the nulls
        $self->_remove_nulls;

        $self->_sanity_check;

        $self->{_parsed_document} = [$self->parsed_body];
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


# <example> is greedy, and will stop only at another </example> or at
# the end of input.
sub _catch_example {
    my $self = shift;
    my @els  = $self->parsed_body;
    my @out;
    while (@els) {
        my $el = shift @els;
        if ($el->is_start_block('example')) {
            # then enter a subloop and slurp until we find a stop
            while (my $e = shift(@els)) {
                if ($e->is_stop_block('example')) {
                    last
                } else {
                    $el->add_to_string($e->rawline)
                }
            }
            # now we exited the hell loop. We change the element
            $el->will_not_merge(1);
            $el->type("example");
        }
        push @out, $el;
    }
    # and we reset the parsed body;
    $self->parsed_body(\@out);
}

# verses are the other big problem, because they are not regular
# strings and can't be nested (as the example, but it's a slightly
# different case.

sub _catch_verse {
    my $self = shift;
    my @els = $self->parsed_body;
    my @out;
    while (@els) {
        my $el = shift @els;
        if ($el->is_start_block('verse')) {
            while (my $e = shift(@els)) {
                # stop if we find a closed environment
                last if $e->is_stop_block('verse');
                if ($e->is_regular_maybe) {
                    $el->add_to_string($e->rawline)
                } else {
                    # argh, too late! Put it back
                    $self->_debug("Rewinding");
                    unshift @els, $e;
                    last;
                }
            }
            $el->will_not_merge(1);
            $el->type("verse"); # change the type
        }
        push @out, $el;
    }
    # and finally reset
    $self->parsed_body(\@out);
}

sub _pack_lines {
    my $self = shift;
    my @els = $self->parsed_body;
    die "Can't process an empty list\n" unless (@els);
    my @out;
    # insert the first.
    push @out, shift(@els);
    while (my $el = shift(@els)) {
        my $last = $out[$#out];
        # same type, same indentation
        if ($el->can_be_merged and # basically, only regular
            $last->can_merge_next) {
            $last->add_to_string($el->string)
        }
        # tables will merge only with themselves
        elsif ($el->type eq 'table' and
               $last->type eq 'table') {
            $last->add_to_string($el->string)
        }
        else {
            push @out, $el;
        }
    }
    $self->parsed_body(\@out);
}

sub _process_lists {
    my $self = shift;
    my @els = $self->parsed_body;
    die "Can't process an empty list\n" unless (@els);
    my @out;
    my @listpile;

    while (my $el = shift(@els)) {

        # first, check if can be in list. If not, empty the queue.
        unless ($el->can_be_in_list) {
            while (@listpile) {
                my $pending = pop(@listpile)->{block};
                # we create an element to close all
                push @out, Text::Amuse::Element->new("</$pending>");
            }
            # push the element
            push @out, $el;
            next;
        }
        # ignore the null, just push it into the output
        if ($el->type eq 'null') {
            push @out, $el;
            next;
        }
        # are we actually in a list?
        unless (@listpile or $el->type eq 'li') {
            # no? good!
            push @out, $el;
            next 
        }
        
        # if we're still here, we are actually in a list
        # no pile, this is the first element

        unless (@listpile) {
            die "Something went wrong!\n" unless $el->type eq 'li';
            # first the block type;
            my $block = $el->block;
            push @listpile, { block => $block,
                              indentation => $el->indentation };
            push @listpile, { block => "li",
                              indentation => $el->indentation };
            push @out, Text::Amuse::Element->new("<$block>");
            push @out, Text::Amuse::Element->new("<li>");
            # change the type, it's a paragraph now
            $el->type('regular');
            push @out, $el;
            next;
        }
        
        # if we're here, we have an existing list, so we check the
        # indentation.
        
        # the type is regular: It can only close or continue
        if ($el->type eq 'regular') {
            $el->block(""); # it's no more a quote/center/right
            # equal or major indentation, just append and next
            if ($el->indentation >= $listpile[$#listpile]->{indentation}) {
                push @out, $el;
                next;
            }
            # and while it's minor, pop the pile
            while (@listpile and $el->indentation < $listpile[$#listpile]->{indentation}) {
                my $pending = pop(@listpile)->{block};
                push @out, Text::Amuse::Element->new("</$pending>");
                # print "Listpile: ", Dumper(\@listpile), "\nElement:", Dumper($el);
            }
            # all done
            push @out, $el;
            next;
        }

        # check if it's all OK
        die "We broke the module!" unless $el->type eq 'li';
        # we're here, change the type as we're done
        $el->type('regular');

        if ($el->indentation == $listpile[$#listpile]->{indentation}) {
            # if the indentation is equal, we don't need to touch the pile,
            # as it was useless to pop and push the same li element.
            push @out, Text::Amuse::Element->new("</li>");
            push @out, Text::Amuse::Element->new("<li>");
            push @out, $el;
            next;
        }
        # indentation is major, open a new level
        elsif ($el->indentation > $listpile[$#listpile]->{indentation}) {
            my $block = $el->block;
            push @listpile, { block => $block,
                              indentation => $el->indentation };
            push @listpile, { block => "li",
                              indentation => $el->indentation };
            push @out, Text::Amuse::Element->new("<$block>");
            push @out, Text::Amuse::Element->new("<li>");
            push @out, $el;
            next;
        }
        # if it's minor, we pop from the pile until we are ok
        while(@listpile and
              $el->indentation < $listpile[$#listpile]->{indentation}) {
            my $pending = pop(@listpile)->{block};
            push @out, Text::Amuse::Element->new("</$pending>");
        }
        # here we reached the desired level
        if (@listpile) {
            push @out, Text::Amuse::Element->new("</li>");
            push @out, Text::Amuse::Element->new("<li>");
        }
        # if by chance, we emptied all, something is wrong, so start anew.
        else {
            my $block = $el->block;
            push @listpile, { block => $block,
                              indentation => $el->indentation };
            push @listpile, { block => "li",
                              indentation => $el->indentation };
            push @out, Text::Amuse::Element->new("<$block>");
            push @out, Text::Amuse::Element->new("<li>");

        }
        push @out, $el;
    }

    # be sure to have the pile empty
    while (@listpile) {
        my $pending = pop(@listpile)->{block};
        # we create an element to close all
        push @out, Text::Amuse::Element->new("</$pending>");
    }
    foreach my $check (@out) {
        die "Found a stray type!" . $check->string . ":" . $check->type
          if $check->type =~ m/^(li|[uo]l)/;
    }
    $self->parsed_body(\@out);    
}

sub _unroll_blocks {
    my $self = shift;
    my @els = $self->parsed_body;
    my @out;
    while (my $el = shift @els) {
        if ($el->can_be_regular) {
            my $block = $el->block;
            $el->block("");
            push @out, Text::Amuse::Element->new("<$block>");
            push @out, $el;
            push @out, Text::Amuse::Element->new("</$block>");
        }
        else { push @out, $el }
    }
    $self->parsed_body(\@out);
}

sub _store_footnotes {
    my $self = shift;
    my @els = $self->parsed_body;
    my @out;
    my %footnotes;
    while (my $el = shift(@els)) {
        if ($el->type eq 'footnote') {
            if ($el->removed =~ m/\[([0-9]+)\]/) {
                warn "Overwriting footnote number $1" if exists $footnotes{$1};
                $footnotes{$1} = $el;
            }
            else { die "Something is wrong here! <" . $el->removed . ">"
                     . $el->string . "!" }
        }
        else {
            push @out, $el;
        }
    }
    $self->parsed_body(\@out);
    $self->_raw_footnotes(\%footnotes);
    return;
}

sub _remove_nulls {
    my $self = shift;
    my @els = $self->parsed_body;
    my @out;
    while (my $el = shift(@els)) {
        unless ($el->type eq 'null') {
            push @out, $el;
        }
    }
    $self->parsed_body(\@out);
}

sub _sanity_check {
    my $self = shift;
    my @els = $self->parsed_body;
    my @pile;
    my @out;
    while (my $el = shift(@els)) {
        if ($el->type eq 'startblock') {
            push @pile, $el->block;
            $self->_debug("Pushing " . $el->block);
            die "Uh?\n" unless $el->block;
        }
        elsif ($el->type eq 'stopblock') {
            my $exp = pop @pile;
            unless ($exp and $exp eq $el->block) {
                warn "Couldn't retrieve " . $el->block . " from the pile\n";
                # put it back
                push @pile, $exp if $exp;
                # so what to do here? just removed it
                next;
            }
        }
        elsif (@pile and $el->should_close_blocks) {
            while (@pile) {
                my $block = shift(@pile);
                warn "Forcing the closing of $block\n";
                push @out, Text::Amuse::Element->new("</$block>");
            }
        }
        push @out, $el;
    }
    # do we still have things into the pile?
    while (@pile) {
        my $block = shift(@pile);
        $self->_debug("forcing the closing of $block");
        # force the closing
        push @out, Text::Amuse::Element->new("</$block>");
    }
    $self->parsed_body(\@out);
}


1;
