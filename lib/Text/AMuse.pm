package Text::AMuse;

use 5.010001;
use strict;
use warnings;
use Text::AMuse::Element;

=head1 NAME

Text::AMuse - The great new Text::AMuse!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Text::AMuse;

    my $foo = Text::AMuse->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

=head3 new(file => $filename)

=cut

sub new {
    my $class = shift;
    my %args;
    my $self;
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
    return @lines;
}


sub _split_body_and_directives {
    my $self = shift;
    my (%directives, @body);
    my $in_meta = 1;
    my $lastdirective;
    my @input = $self->get_lines;
    # scan the line
    while (@input) {
        my $line = shift @input;
        if ($in_meta) {
            # reset the directives on blank lines
            if ($line =~ m/^\s*$/s) {
                $lastdirective = undef;
            } elsif ($line =~ m/^\#(\w+)\s+(.+)$/s) {
                my $dir = $1;
                $directives{$dir} = $2;
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
hash, with key/value pairs

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
L<Text::AMuse::Element> object

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
    my @parsed = (Text::AMuse::Element->new("")); 
    foreach my $l ($self->raw_body) {
        push @parsed, Text::AMuse::Element->new($l);
    }
    $self->{parsed_body} = \@parsed;
    return @{$self->{parsed_body}};
}

=head2 document

Return the list of the elements which compose the body, once they have
properly parsed and packed.

=cut

sub document {
    my $self = shift;

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
    
    # all done, return something
    return $self->parsed_body;
}

=head3 get_footnote

Accessor to the internal footnotes hash. You can access the footnote
with a numerical argument.

=cut

sub get_footnote {
    my ($self, $arg) = @_;
    return undef unless $arg;
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
                push @out, Text::AMuse::Element->new("</$pending>");
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
            push @out, Text::AMuse::Element->new("<$block>");
            push @out, Text::AMuse::Element->new("<li>");
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
            while ($el->indentation < $listpile[$#listpile]->{indentation}) {
                my $pending = pop(@listpile)->{block};
                push @out, Text::AMuse::Element->new("</$pending>");
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
            push @out, Text::AMuse::Element->new("</li>");
            push @out, Text::AMuse::Element->new("<li>");
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
            push @out, Text::AMuse::Element->new("<$block>");
            push @out, Text::AMuse::Element->new("<li>");
            push @out, $el;
            next;
        }
        # if it's minor, we pop from the pile until we are ok
        while(@listpile and
              $el->indentation < $listpile[$#listpile]->{indentation}) {
            my $pending = pop(@listpile)->{block};
            push @out, Text::AMuse::Element->new("</$pending>");
        }
        # here we reached the desired level
        if (@listpile) {
            push @out, Text::AMuse::Element->new("</li>");
            push @out, Text::AMuse::Element->new("<li>");
        }
        # if by chance, we emptied all, something is wrong, so start anew.
        else {
            my $block = $el->block;
            push @listpile, { block => $block,
                              indentation => $el->indentation };
            push @listpile, { block => "li",
                              indentation => $el->indentation };
            push @out, Text::AMuse::Element->new("<$block>");
            push @out, Text::AMuse::Element->new("<li>");

        }
        push @out, $el;
    }

    # be sure to have the pile empty
    while (@listpile) {
        my $pending = pop(@listpile)->{block};
        # we create an element to close all
        push @out, Text::AMuse::Element->new("</$pending>");
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
            push @out, Text::AMuse::Element->new("<$block>");
            push @out, $el;
            push @out, Text::AMuse::Element->new("</$block>");
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
            if ($el->removed =~ m/\[([0-9])\]/) {
                warn "Overwriting footnote number $1" if exists $footnotes{$1};
                $footnotes{$1} = $el->string;
            }
            else { die "Something is wrong here!\n" }
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


=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-amuse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-AMuse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::AMuse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-AMuse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-AMuse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-AMuse>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-AMuse/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Text::AMuse
