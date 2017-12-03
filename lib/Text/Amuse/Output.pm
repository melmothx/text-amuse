package Text::Amuse::Output;
use strict;
use warnings;
use utf8;
use Text::Amuse::Output::Image;
use Text::Amuse::InlineElement;
# use Data::Dumper;

=head1 NAME

Text::Amuse::Output - Internal module for L<Text::Amuse> output

=head1 SYNOPSIS

The module is used internally by L<Text::Amuse>, so everything here is
pretty much internal only (and underdocumented).

=head1 Basic LaTeX preamble

  \documentclass[DIV=9,fontsize=10pt,oneside,paper=a5]{scrbook}
  \usepackage{graphicx}
  \usepackage{alltt}
  \usepackage{verbatim}
  \usepackage[hyperfootnotes=false,hidelinks,breaklinks=true]{hyperref}
  \usepackage{bookmark}
  \usepackage[stable]{footmisc}
  \usepackage{enumerate}
  \usepackage{longtable}
  \usepackage[normalem]{ulem}
  \usepackage{wrapfig}
  
  % avoid breakage on multiple <br><br> and avoid the next [] to be eaten
  \newcommand*{\forcelinebreak}{~\\\relax}
  % this also works
  % \newcommand*{\forcelinebreak}{\strut\\{}}

  \newcommand*{\hairline}{%
    \bigskip%
    \noindent \hrulefill%
    \bigskip%
  }
  
  % reverse indentation for biblio and play
  
  \newenvironment{amusebiblio}{
    \leftskip=\parindent
    \parindent=-\parindent
    \bigskip
    \indent
  }{\bigskip}
  
  \newenvironment{amuseplay}{
    \leftskip=\parindent
    \parindent=-\parindent
    \bigskip
    \indent
  }{\bigskip}
  
  \newcommand{\Slash}{\slash\hspace{0pt}}
  
=head2 METHODS

=head3 Text::Amuse::Output->new(document => $obj, format => "ltx")

Constructor. Format can be C<ltx> or C<html>, while document must be a
L<Text::Amuse::Document> object.

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    die "Missing document object!\n" unless $opts{document};
    die "Missing or wrong format!\n" unless ($opts{format} and ($opts{format} eq 'ltx' or
                                                                $opts{format} eq 'html'));
    my $self = { document => $opts{document},
                 fmt => $opts{format} };
    bless $self, $class;
}

=head3 document

Accessor to the L<Text::Amuse::Document> object (read-only, but you
may call its method on that.

=cut

sub document {
    return shift->{document};
}

=head3 fmt

Accessor to the current format (read-only);

=cut

sub fmt {
    return shift->{fmt};
}

=head3 is_html

True if the format is html

=head3 is_latex

True if the format is latex

=cut

sub is_latex {
    return shift->fmt eq 'ltx';
}

sub is_html {
    return shift->fmt eq 'html';
}

=head3 process

This method returns a array ref with the processed chunks. To get
a sensible output you will have to join the pieces yourself.

We don't return a joined string to avoid copying large amounts of
data.

  my $splat_pages = $obj->process(split => 1);
  foreach my $html (@$splat_pages) {
      # ...templating here...
  }

If the format is C<html>, the option C<split> may be passed. Instead
of a arrayref of chunks, an arrayref with html pages will be
returned. Each page usually starts with an heading, and it's without
<head> <body>. Footnotes are flushed and inserted at the end of each
pages.

E.g.

  print @{$obj->process};

=cut

sub process {
    my ($self, %opts) = @_;
    my (@pieces, @splat);
    my $split = $opts{split};
    my $imagere = $self->image_re;
    $self->reset_toc_stack;
    # loop over the parsed elements
    foreach my $el ($self->document->elements) {
        if ($el->type eq 'null') {
            next;
        }
        if ($el->type eq 'startblock') {
            die "startblock with string passed!: " . $el->string if $el->string;
            push @pieces, $self->blkstring(start => $el->block, start_list_index => $el->start_list_index);
        }
        elsif ($el->type eq 'stopblock') {
            die "stopblock with string passed!:" . $el->string if $el->string;
            push @pieces, $self->blkstring(stop => $el->block);
        }
        elsif ($el->type eq 'regular') {
            # manage the special markup
            if ($el->string =~ m/^\s*-----*\s*$/s) {
                push @pieces, $self->manage_hr($el);
            }
            # an image by itself, so avoid it wrapping with <p></p>,
            # but only if just 1 is found. With multiple one, we get
            # incorrect output anyway, so who cares?
            elsif ($el->string =~ m/^\s*\[\[\s*$imagere\s*\]
                                    (\[[^\]\[]+?\])?\]\s*$/sx and
                   $el->string !~ m/\[\[.*\[\[/s) {
                push @pieces, $self->manage_regular($el);
            }
            else {
                push @pieces, $self->manage_paragraph($el);
            }
        }
        elsif ($el->type eq 'standalone') {
            push @pieces, $self->manage_regular($el);
        }
        elsif ($el->type eq 'dt') {
            push @pieces, $self->manage_regular($el);
        }
        elsif ($el->type =~ m/h[1-6]/) {

            # if we want a split html, we cut here and flush the footnotes
            if ($el->type =~ m/h[1-4]/ and $split and @pieces) {
                
                if ($self->is_html) {
                    foreach my $fn ($self->flush_footnotes) {
                        push @pieces, $self->manage_html_footnote($fn);
                    }
                    foreach my $nested ($self->flush_secondary_footnotes) {
                        push @pieces, $self->manage_html_footnote($nested);
                    }
                    die "Footnotes still in the stack!" if $self->flush_footnotes;
                    die "Secondary footnotes still in the stack!" if $self->flush_secondary_footnotes;
                }
                push @splat, join("", @pieces);
                @pieces = ();
                # all done
            }

            # then continue as usual
            push @pieces, $self->manage_header($el);
        }
        elsif ($el->type eq 'verse') {
            push @pieces, $self->manage_verse($el);
        }
        elsif ($el->type eq 'comment') {
            push @pieces, $self->manage_comment($el);
        }
        elsif ($el->type eq 'table') {
            push @pieces, $self->manage_table($el);
        }
        elsif ($el->type eq 'example') {
            push @pieces, $self->manage_example($el);
        }
        elsif ($el->type eq 'newpage') {
            push @pieces, $self->manage_newpage($el);
        }
        else {
            die "Unrecognized element: " . $el->type;
        }
    }
    if ($self->is_html) {
        foreach my $fn ($self->flush_footnotes) {
            push @pieces, $self->manage_html_footnote($fn);
        }
        foreach my $nested ($self->flush_secondary_footnotes) {
            push @pieces, $self->manage_html_footnote($nested);
        }
        die "Footnotes still in the stack!" if $self->flush_footnotes;
        die "Secondary footnotes still in the stack!" if $self->flush_secondary_footnotes;
    }

    if ($split) {
        # catch the last
        push @splat, join("", @pieces);
        # and return
        return \@splat;
    }
    return \@pieces;
}

=head3 header

Return the formatted header as an hashref with key/value
pairs.

=cut

sub header {
    my $self = shift;
    my %directives = $self->document->raw_header;
    my %out;
    while (my ($k, $v) = each %directives) {
        $out{$k} = $self->manage_regular($v);
    }
    return \%out;
}


=head2 INTERNAL METHODS

=head3 add_footnote($element)

Add the footnote to the internal list of found footnotes.

=cut

sub add_footnote {
    my ($self, $fn) = @_;
    return unless defined($fn);
    if ($fn->type eq 'footnote') {
        $self->_add_primary_footnote($fn);
    }
    elsif ($fn->type eq 'secondary_footnote') {
        $self->_add_secondary_footnote($fn);
    }
    else {
        die "Wrong element type passed: " . $fn->type . " " . $fn->string;
    }
}

sub _add_primary_footnote {
    my ($self, $fn) = @_;
    unless (defined $self->{_fn_list}) {
        $self->{_fn_list} = [];
    }
    push @{$self->{_fn_list}}, $fn;
}

sub _add_secondary_footnote {
    my ($self, $fn) = @_;
    unless (defined $self->{_sec_fn_list}) {
        $self->{_sec_fn_list} = [];
    }
    push @{$self->{_sec_fn_list}}, $fn;
}

=head3 flush_footnotes

Return the list of primary footnotes found as a list of elements.

=head3 flush_secondary_footnotes

Return the list of secondary footnotes found as a list of elements.


=cut

sub flush_footnotes {
    my $self = shift;
    return unless (defined $self->{_fn_list});
    # if we flush, we flush and forget, so we don't collect them again
    # on the next call
    return @{delete $self->{_fn_list}};
}

sub flush_secondary_footnotes {
    my $self = shift;
    # as above
    return unless (defined $self->{_sec_fn_list});
    return @{delete $self->{_sec_fn_list}};
}

=head3 manage_html_footnote

=cut

sub manage_html_footnote {
    my ($self, $element) = @_;
    return unless $element;
    my $fn_num = $element->footnote_index;
    my $fn_symbol = $element->footnote_symbol;
    my $class;
    if ($element->type eq 'footnote') {
        $class = 'fnline';
    }
    elsif ($element->type eq 'secondary_footnote') {
        $class = 'secondary-fnline';
    }
    else {
        die "wrong type " . $element->type . '  ' . $element->string;
    }
    my $chunk = qq{\n<p class="$class"><a class="footnotebody"} . " "
      . qq{href="#fn_back${fn_num}" id="fn${fn_num}">$fn_symbol</a> } .
        $self->manage_regular($element) .
          qq{</p>\n};
}

=head3 blkstring 

=cut

sub blkstring  {
    my ($self, $start_stop, $block, %attributes) = @_;
    die "Wrong usage! Missing params $start_stop, $block"
      unless ($start_stop && $block);
    die "Wrong usage!\n" unless ($start_stop eq 'stop' or
                                 $start_stop eq 'start');
    my $table = $self->blk_table;
    die "Table is missing an element $start_stop  $block "
      unless exists $table->{$block}->{$start_stop}->{$self->fmt};
    my $string = $table->{$block}->{$start_stop}->{$self->fmt};
    if (ref($string)) {
        return $string->(%attributes);
    }
    else {
        return $string;
    }
}

=head3 manage_regular($element_or_string, %options)

Main routine to transform a string to the given format

Options:

=over 4

=item nolinks

If set to true, do not parse the links and consider them plain strings

=item anchors

If set to true, parse the anchors and return two elements, the first
is the processed string, the second is the processed anchors string.

=back

=cut

sub _get_unique_counter {
    my $self = shift;
    ++$self->{_unique_counter};
}

sub inline_elements {
    my ($self, $string) = @_;
    return unless $string;
    my @list;
    if ($string =~ m{\A\s*\<br */*\>\s*\z}) {
        return Text::Amuse::InlineElement->new(string => $string,
                                               type => 'bigskip',
                                               last_position => length($string),
                                               fmt => $self->fmt,
                                              );
    }
    while ($string =~ m{\G # last match
                        (?<text>.*?) # something not greedy, even nothing
                        (?<raw>
                            # these are OR, so order matters.
                            # link is the most greedy, as it could have inline markup in the second argument.
                            (?<link>         \[\[[^\[].*?\]\])      |
                            (?<open_verb>    \<verbatim\>)     |
                            (?<close_verb>   \<\/verbatim\>)  |
                            (?<pri_footnote> \s*\[[0-9]+\]) |
                            (?<sec_footnote> \s*\{[0-9]+\}) |
                            (?<tag> \<
                                (?<close>\/?)
                                (?<tag_name> strong | em |  code | strike | del | sup |  sub )
                                \>
                            ) |
                            (?<inline>(?:\*\*\*|\*\*|\*|\=)) |
                            (?<anchor> ^\x{20}*\#[A-Za-z][A-Za-z0-9]+\x{20}*$) |
                            (?<br> \s*\< br *\/*\>)
                        )}gcxms) {
        # this is a mammuth, but hey
        my %captures = %+;
        my $text = delete $captures{text};
        my $raw = delete $captures{raw};
        my $position = pos($string);
        if (length($text)) {
            push @list, Text::Amuse::InlineElement->new(string => $text,
                                                        type => 'text',
                                                        last_position => $position - length($raw),
                                                        fmt => $self->fmt,
                                                       );
        }
        my %args = (
                    string => $raw,
                    last_position => $position,
                    fmt => $self->fmt,
                   );
        if (delete $captures{tag}) {
            my $close = delete $captures{close};
            $args{type} = $close ? 'close' : 'open';
            $args{tag} = delete $captures{tag_name} or die "Missing tag_name, this is a bug:  <$string>";
        }
        elsif (my $tag = delete $captures{inline}) {
            $args{type} = 'inline';
            $args{tag} = $tag;
        }
        elsif (delete $captures{close_inline}) {
            $args{type} = 'close_inline';
            $args{tag} = delete $captures{close_inline_name} or die "Missing close_inline_name in <$string>";
        }
        else {
            my ($type, @rest) = keys %captures;
            die "Too many keys in <$string> the capture hash: @rest" if @rest;
            delete $captures{$type};
            $args{type} = $type;
        }
        die "Unprocessed captures %captures in <$string>" if %captures;
        push @list, Text::Amuse::InlineElement->new(%args);
    }
    my $offset = (@list ? $list[-1]->last_position : 0);
    my $last_chunk = substr $string, $offset;
    push @list, Text::Amuse::InlineElement->new(string => $last_chunk,
                                                type => 'text',
                                                fmt => $self->fmt,
                                                last_position => $offset + length($last_chunk),
                                               );
    my $last = $#list;
  PARSEINLINE:
    for (my $i = 0; $i < @list; $i++) {
        if ($list[$i]->type eq 'inline') {
            my $next = $i + 1;
            my $previous = $i - 1;
            # check back and forward, just to mark as open or close
            if ($i == 0) {
                # first element, can be open if next is not a space
                if ($next <= $last and
                    $list[$next]->string =~ m/\A\S/) {
                    $list[$i]->type('open_inline');
                    next PARSEINLINE;
                }
            }
            elsif ($i == $last) {
                # last element, can only close
                if ($list[$previous]->string =~ m/\S\z/) {
                    $list[$i]->type('close_inline');
                    next PARSEINLINE;
                }
            }
            else {
                # we have both next and previous
                my $prev_string = $list[$previous]->string;
                my $next_string = $list[$next]->string;
                # we give preference to the closing. Logic here is weak.
                if ($prev_string =~ m/\S\z/ and
                       $next_string !~ m/\A\w/) {
                    $list[$i]->type('close_inline');
                    next PARSEINLINE;
                }
                elsif ($prev_string !~ m/\w\z/ and
                    $next_string =~ m/\A\S/) {
                    $list[$i]->type('open_inline');
                    next PARSEINLINE;
                }
            }
            $list[$i]->type('text');
        }
    }
    die "Chunks lost during processing <$string>" unless $string eq join('', map { $_->string } @list);
    return @list;
}

sub manage_regular {
    my ($self, $el, %opts) = @_;
    my $string;
    my $insert_primary_footnote = 1;
    my $insert_secondary_footnote = 1;
    my $el_object;
    # we can accept even plain string;
    if (ref($el) eq "") {
        $string = $el;
    } else {
        $el_object = $el;
        $string = $el->string;
        if ($el->type eq 'footnote') {
            $insert_primary_footnote = 0;
        }
        elsif ($el->type eq 'secondary_footnotes') {
            $insert_primary_footnote = 0;
            $insert_secondary_footnote = 0;
        }
    }
    unless (defined $string) {
        $string = '';
    }

    # we do the processing in more steps. It may be more expensive,
    # but at least the code should be clearer.

    my @pieces = $self->inline_elements($string);
    my @processed;
  VERBATIMPIECE:
    while (@pieces) {
        my $piece = shift @pieces;
        if (@processed and $processed[-1]->type eq 'verbatim') {
            if ($piece->type eq 'close_verb') {
                # push an empty text just to mark the end of verbatim.
                push @processed, Text::Amuse::InlineElement->new(string => '',
                                                                 type => 'text',
                                                                 fmt => $self->fmt,
                                                                 last_position => $piece->last_position);
            }
            else {
                $processed[-1]->append($piece);
            }
            next VERBATIMPIECE;
        }
        elsif ($piece->type eq 'open_verb') {
            push @processed, Text::Amuse::InlineElement->new(string => '',
                                                             fmt => $self->fmt,
                                                             type => 'verbatim',
                                                             last_position => $piece->last_position);
            next VERBATIMPIECE;
        }
        elsif ($piece->type eq 'close_verb') {
            # this is lonely tag
            $piece->type('text');
        }
        push @processed, $piece;
    }
    # now validate the tags: open and close
    my @tagpile;
    while (@processed) {
        my $piece = shift @processed;
        if ($piece->type eq 'open') {
            # look forward for a matching tag
            if (grep { $_->type eq 'close' and $_->tag eq $piece->tag } @processed) {
                push @tagpile, $piece->tag;
            }
            else {
                warn "Found opening tag " . $piece->string
                  . " in <$string> without a matching closing tag. "
                  . "Leaving it as-is, but it's unlikely you want this. "
                  . "To suppress this warning, wrap it around <verbatim>\n";
                $piece->type('text');
            }
        }
        elsif ($piece->type eq 'close') {
            # check if there is a matching opening
            if (@tagpile and $tagpile[-1] eq $piece->tag) {
                # all match, can go
                # and remove from the pile
                pop @tagpile;
            }
            else {
                while (@tagpile and $tagpile[-1] ne $piece->tag) {
                    # empty the pile untile we find the matching one,
                    # if any, we're in error anyway, but we have some
                    # slight chance to recover.
                    pop @tagpile;
                }
                warn "Found closing element " . $piece->string
                  . " in <$string> without a matching opening tag. "
                  . "Leaving it as-is, but it's unlikely you want this. "
                  . "To suppress this warning, wrap it around <verbatim>\n";
                $piece->type('text');
            }
        }
        push @pieces, $piece;
    }

    # print Dumper(\@pieces);

    while (@tagpile) {
        my $unclosed = pop @tagpile;
        warn "Found unclosed tag $unclosed in string <$string>, closing it\n";
        push @pieces, Text::Amuse::InlineElement->new(string => '',
                                                      fmt => $self->fmt,
                                                      tag => $unclosed,
                                                      type => 'close');
    }

    # finally, we have to decide if = and * are markup element or
    # normal pieces and change the type accordingly.

    while (@pieces) {
        my $piece = shift @pieces;
        if ($piece->type eq 'close_inline') {
            if (@tagpile and $tagpile[-1] eq $piece->tag) {
                # all match, can go
                # and remove from the pile
                pop @tagpile;
                push @processed, $piece->unroll;
            }
            else {
                # this is just a text material like this*
                $piece->type('text');
                push @processed, $piece;
            }
        }
        elsif ($piece->type eq 'open_inline') {
            # check if in the remaning chunks there is a matching closing
            if (grep { $_->type eq 'close_inline' && $_->tag eq $piece->tag } @pieces) {
                push @tagpile, $piece->tag;
                push @processed, $piece->unroll;
            }
            else {
                $piece->type('text');
                push @processed, $piece;
            }
        }
        else {
            push @processed, $piece;
        }
    }

    # now we're hopefully set.
    my (@out, @anchors);
  CHUNK:
    while (@processed) {
        my $piece = shift @processed;
        if ($piece->type eq 'link') {
            if ($opts{nolinks}) {
                $piece->type('text');
            }
            else {
                push @out, $self->linkify($piece->string);
                next CHUNK;
            }
        }
        elsif ($piece->type eq 'pri_footnote') {
            if ($insert_primary_footnote and
                my $pri_fn = $self->document->get_footnote($piece->string)) {
                if ($self->is_html and $piece->string =~ m/\A(\s+)/) {
                    push @out, $1;
                }
                push @out, $self->_format_footnote($pri_fn);
                next CHUNK;
            }
            else {
                $piece->type('text');
            }
        }
        elsif ($piece->type eq 'sec_footnote') {
            if ($insert_secondary_footnote and
                my $sec_fn = $self->document->get_footnote($piece->string)) {
                if ($self->is_html and $piece->string =~ m/\A(\s+)/) {
                    push @out, $1;
                }
                push @out, $self->_format_footnote($sec_fn);
                next CHUNK;
            }
            else {
                $piece->type('text');
            }
        }
        elsif ($piece->type eq 'anchor') {
            push @anchors, $piece->stringify;
            next CHUNK;
        }
        push @out, $piece->stringify;
    }
    if ($opts{anchors}) {
        return join('', @out), join('', @anchors);
    }
    else {
        return join('', @out);
    }
}

sub _format_footnote {
    my ($self, $element) = @_;
    if ($self->is_latex) {
        my $footnote = $self->manage_regular($element);
        $footnote =~ s/\s+/ /gs;
        $footnote =~ s/ +$//s;
        # covert <br> to \par in latex. those \\ in the footnotes are
        # pretty much ugly. Also the syntax doesn't permit to have
        # multiple paragraphs separated by a blank line in a footnote.
        # However, this is going to fail with footnotes in the
        # headings, so we have to call \endgraf instead
        $footnote =~ s/\\forcelinebreak /\\endgraf /g;
        if ($element->type eq 'secondary_footnote') {
            return '\footnoteB{' . $footnote . '}';
        }
        else {
            return '\footnote{' . $footnote . '}';
        }
    } elsif ($self->is_html) {
        # in html, just remember the number
        $self->add_footnote($element);
        my $fn_num = $element->footnote_index;
        my $fn_symbol = $element->footnote_symbol;
        return
          qq(<a href="#fn${fn_num}" class="footnote" ) .
          qq(id="fn_back${fn_num}">$fn_symbol</a>);
    }
    else {
        die "Not reached"
    }
}

=head3 safe($string)

Be sure that the strings passed are properly escaped for the current
format, to avoid command injection.

=cut

sub safe {
    my ($self, $string) = @_;
    return Text::Amuse::InlineElement->new(fmt => $self->fmt,
                                    string => $string,
                                    type => 'verbatim')->stringify;
}


=head3 manage_paragraph

=cut


sub manage_paragraph {
    my ($self, $el) = @_;
    my ($body, $anchors) = $self->manage_regular($el, anchors => 1);
    chomp $body;
    return $self->blkstring(start  => "p") .
      $anchors .
      $body . $self->blkstring(stop => "p");
}

=head3 manage_header

=cut

sub manage_header {
    my ($self, $el) = @_;
    my $body_with_no_footnotes = $el->string;
    my $has_fn;
    my $catch_fn = sub {
        if ($self->document->get_footnote($_[0])) {
            $has_fn++;
            return ''
        } else {
            return $1;
        }
    };
    $body_with_no_footnotes =~ s/(
                                     \{ [0-9]+ \}
                                 |
                                     \[ [0-9]+ \]
                                 )
                                /$catch_fn->($1)/gxe;
    undef $catch_fn;
    my ($body_for_toc);
    if ($has_fn) {
        ($body_for_toc) = $self->manage_regular($body_with_no_footnotes, nolinks => 1, anchors => 1);
    }
    my ($body, $anchors) = $self->manage_regular($el, nolinks => 1, anchors => 1);
    chomp $body;
    if (defined $body_for_toc) {
        $body_for_toc =~ s/\s+/ /g;
        $body_for_toc =~ s/\s+\z//;
    }
    my $leading = $self->blkstring(start => $el->type,
                                   toc_entry => ($has_fn ? $body_for_toc : undef));
    my $trailing = $self->blkstring(stop => $el->type);
    if ($anchors) {
        if ($self->is_html) {
            #insert the <a> before the text
            $leading .= $anchors;
        }
        elsif ($self->is_latex) {
            # latex doesn't like it inside \chapter{}
            $trailing .= $anchors;
        }
        else { die "Not reached" }
    }
    # add them to the ToC for html output;
    if ($el->type =~ m/h([1-4])/) {
        my $level = $1;
        my $tocline = $body;
        my $index = $self->add_to_table_of_contents($level => (defined($body_for_toc) ? $body_for_toc : $body));
        $level++; # increment by one
        die "wtf, no index for toc?" unless $index;

        # inject the id into the html ToC (and the anchor)
        if ($self->is_html) {
            $leading = "<h" . $level .
              qq{ id="toc$index">} . $anchors;
        }
    }
    return $leading . $body . $trailing . "\n";
}

=head3 add_to_table_of_contents

When we catch an header, we save it in the Output object, so we can
emit the ToC. Level 5 is excluded as per doc.

It returns the numerical index (so you can inject the id).

=cut

sub add_to_table_of_contents {
    my ($self, $level, $string) = @_;
    return unless ($level and defined($string) and $string ne '');
    unless (defined $self->{_toc_entries}) {
        $self->{_toc_entries} = [];
    }
    my $index = scalar(@{$self->{_toc_entries}});
    push @{$self->{_toc_entries}}, { level => $level,
                                     string => $string,
                                     index => ++$index,
                                   };
    return $index;
}

=head3 reset_toc_stack

Clear out the list. This is called at the beginning of the main loop,
so we don't collect duplicates over multiple runs.

=cut

sub reset_toc_stack {
    my $self = shift;
    delete $self->{_toc_entries} if defined $self->{_toc_entries};
}

=head3 table_of_contents

Emit the formatted ToC (if any). Please note that this method works
even for the LaTeX format, even if does not produce usable output.

This because we can test if we need to emit a table of contents
looking at this without searching the whole output.

The output is a list of hashref, where each hashref has the following keys:

=over 4

=item level

The level of the header. Currently we store only levels 1-4, defining
part(1), chapter(2), section(3) and subsection(4). Any other value
means something is off (a.k.a., you found a bug).

=item index

The index of the entry, starting from 1.

=item string

The output.

=back

The hashrefs are returned as copies, so they are safe to
manipulate.

=cut

sub table_of_contents {
    my $self = shift;
    my $internal_toc = $self->{_toc_entries};
    my @toc;
    return @toc unless $internal_toc; # no ToC gets undef
    # do a deep copy and return;
    foreach my $entry (@$internal_toc) {
        push @toc, { %$entry };
    }
    return @toc;
}

=head3 manage_verse

=cut

sub manage_verse {
    my ($self, $el) = @_;
    my ($lead, $stanzasep);
    if ($self->is_html) {
        $lead = "&nbsp;";
        $stanzasep = "\n<br /><br />\n";
    }
    elsif ($self->is_latex) {
        $lead = "~";
        $stanzasep = "\n\n";
    }
    else { die "Not reached" }

    my (@chunks) = split(/\n/, $el->string);
    my (@out, @stanza, @anchors);
    foreach my $l (@chunks) {
        if ($l =~ m/^( *)(.+?)$/s) {
            my $leading = $lead x length($1);
            my ($text, $anchors) = $self->manage_regular($2, anchors => 1);
            if ($anchors) {
                push @anchors, $anchors;
            }
            if (length($text)) {
                push @stanza, $leading . $text;
            }
        }
        elsif ($l =~ m/^\s*$/s) {
            push @out, $self->_format_stanza(\@stanza, \@anchors);
            die "wtf" if @stanza || @anchors;
        }
        else {
            die "wtf?";
        }
    }
    # flush the stanzas and the anchors
    push @out, $self->_format_stanza(\@stanza, \@anchors) if @stanza || @anchors;
    die "wtf" if @stanza || @anchors;

    # process
    return $self->blkstring(start => $el->type) .
      join($stanzasep, @out) . $self->blkstring(stop => $el->type);
}

sub _format_stanza {
    my ($self, $stanza, $anchors) = @_;

    my $eol;
    if ($self->is_html) {
        $eol = "<br />\n";
    }
    elsif ($self->is_latex) {
        $eol = "\\forcelinebreak\n";
    }
    else { die "Not reached" };

    my ($anchor_string, $stanza_string) = ('', '');
    if (@$anchors) {
        $anchor_string = join("\n", @$anchors);
        @$anchors = ();
    }
    if (@$stanza) {
        $stanza_string = join($eol, @$stanza);
        @$stanza = ();
    }
    return $anchor_string . $stanza_string;
}


=head3 manage_comment

=cut

sub manage_comment {
    my ($self, $el) = @_;
    my $body = $self->safe($el->removed);
    chomp $body;
    return $self->blkstring(start => $el->type) .
      $body . $self->blkstring(stop => $el->type);
}

=head3 manage_table

=cut

sub manage_table {
    my ($self, $el) = @_;
    my $thash = $self->_split_table_in_hash($el->string);
    if ($self->is_html) {
        return $self->manage_table_html($thash);
    }
    elsif ($self->is_latex) {
        return $self->manage_table_ltx($thash);
    }
    else { die "Not reached" }
}

=head3 manage_table_html

=cut

sub manage_table_html {
    my ($self, $table) = @_;
    my @out;
    my $map = $self->html_table_mapping;
    # here it's full of hardcoded things, but it can't be done differently
    push @out, "\n<table>";

    # the hash is always defined
    if ($table->{caption} ne "") {
        push @out, "<caption>"
          . $self->manage_regular($table->{caption})
            . "</caption>";
    }

    foreach my $tablepart (qw/head foot body/) {
        next unless @{$table->{$tablepart}};
        push @out, $map->{$tablepart}->{b};
        while (@{$table->{$tablepart}}) {
            my $cells = shift @{$table->{$tablepart}};

            push @out, $map->{btr};
            while (@$cells) {
                my $cell = shift @$cells;
                push @out, $map->{$tablepart}->{bcell},
                  $self->manage_regular($cell),
                    $map->{$tablepart}->{ecell},
                }
            push @out, $map->{etr};
        }
        push @out, $map->{$tablepart}->{e};
    }
    push @out, "</table>\n";
    return join("\n", @out);
}

=head3 manage_table_ltx

=cut

sub manage_table_ltx {
    my ($self, $table) = @_;

    my $out = {
               body => [],
               head => [],
               foot => [],
              };
    foreach my $t (qw/body head foot/) {
        foreach my $rt (@{$table->{$t}}) {
            my @row;
            foreach my $cell (@$rt) {
                # escape all!
                push @row, $self->manage_regular($cell);
            }
            my $texrow = join(q{ & }, @row);
            push @{$out->{$t}}, "\\relax " . $texrow . "  \\\\\n"
        }
    }
    # then we loop over what we have. First head, then body, and
    # finally foot
    my $has_caption;
    if (defined $table->{caption} and $table->{caption} ne '') {
        $has_caption = 1;
    }
    my $textable = '';
    if ($has_caption) {
        $textable .= "\\begin{table}[htbp!]\n";
    }
    else {
        $textable .= "\\bigskip\n\\noindent\n";
    }
    $textable .= " \\begin{minipage}[t]{\\textwidth}\n";
    $textable .= "\\begin{tabularx}{\\textwidth}{" ;
    $textable .= "|X" x $table->{counter};
    $textable .= "|}\n";
    if (my @head = @{$out->{head}}) {
        $textable .= "\\hline\n" . join("", @head);
    }
    if (my @body = @{$out->{body}}) {
        $textable .= "\\hline\n" . join("", @body);
    }
    if (my @foot = @{$out->{foot}}) {
        $textable .= "\\hline\n" . join("", @foot);
    }
    $textable .= "\\hline\n\\end{tabularx}\n";
    if ($has_caption) {
        $textable .= "\n\\caption[]{" .
          $self->manage_regular($table->{caption}) . "}\n";
    }
    $textable .= "\\end{minipage}\n";
    if ($has_caption) {
        $textable .= "\\end{table}\n";
    }
    else {
        $textable .= "\\bigskip\n";
    }
    $textable .= "\n";
    # print $textable;
    return $textable;
}

=head3 _split_table_in_hash

=cut

sub _split_table_in_hash {
    my ($self, $table) = @_;
    return {} unless $table;
    my $output = {
                  caption => "",
                  body => [],
                  head => [],
                  foot => [],
                  counter => 0,
                 };
    foreach my $row (split "\n", $table) {
        if ($row =~ m/^\s*\|\+\s*(.+?)\s*\+\|\s*$/) {
            $output->{caption} = $1;
            next
        }
        my $dest;
        my @cells = split /\|+/, $row;
        if ($output->{counter} < scalar(@cells)) {
            $output->{counter} = scalar(@cells);
        }
        if ($row =~ m/\|\|\|/) {
            push @{$output->{foot}}, \@cells;
        } elsif ($row =~ m/\|\|/) {
            push @{$output->{head}}, \@cells;
        } else {
            push @{$output->{body}}, \@cells;
        }
    }
    # pad the cells with " " if their number doesn't match
    foreach my $part (qw/body head foot/) {
        foreach my $row (@{$output->{$part}}) {
            while (@$row < $output->{counter}) {
                # warn "Found uneven table: " . join (":", @$row), "\n";
                push @$row, " ";
            }
        }
    }
    return $output;
}

=head3 manage_example

=cut

sub manage_example {
    my ($self, $el) = @_;
    my $body = $self->safe($el->string);
    return $self->blkstring(start => $el->type) .
      $body . $self->blkstring(stop => $el->type);
}

=head3 manage_hr

Put an horizontal rule

=cut

sub manage_hr {
    my ($self, $el) = @_;
    die "Wtf?" if $el->string =~ m/\w/s; # don't eat chars by mistake
    if ($self->is_html) {
        return "\n<hr />\n";
    }
    elsif ($self->is_latex) {
        return "\n\\hairline\n\n";
    }
    else { die "Not reached" }
}

=head3 manage_newpage

If it's LaTeX, insert a newpage

=cut

sub manage_newpage {
    my ($self, $el) = @_;
    die "Wtf? " . $el->string if $el->string =~ m/\w/s; # don't eat chars by mistake
    if ($self->is_html) {
        my $out = $self->blkstring(start => 'center') .
          $self->manage_paragraph($el) .
            $self->blkstring(stop => 'center');
        return $out;
    }
    elsif ($self->is_latex) {
        return "\n\\clearpage\n\n";
    }
    else { die "Not reached" }
}


=head2 Links management

=head3 linkify($link)

Here we see if it's a single one or a link/desc pair. Then dispatch

=cut

sub linkify {
    my ($self, $link) = @_;
    die "no link passed" unless defined $link;
    # warn "Linkifying $link";
    if ($link =~ m/^\[\[
                     \s*
                     (.+?) # link
                     \s*
                     \]\[
                     \s*
                     (.+?) # desc
                     \s*
                     \]\]$
                    /sx) {
        return $self->format_links($1, $2);
    }

    elsif ($link =~ m/\[\[
		   \s*
		   (.+?) # link
		   \s*
		   \]\]/sx) {
        return $self->format_single_link($1);
    }

    else {
        die "Wtf??? $link"
    }
}

=head3 format_links

=cut

sub format_links {
    my ($self, $link, $desc) = @_;
    $desc = $self->manage_regular($desc);
    # first the images
    if (my $image = $self->find_image($link)) {
        my $src = $image->filename;
        $self->document->attachments($src);
        $image->desc($desc);
        return $image->output;
    }
    # links
    if ($link =~ m/\A\#([A-Za-z][A-Za-z0-9]*)\z/) {
        my $linkname = $1;
        if ($self->is_html) {
            $link = "#text-amuse-label-$linkname";
        }
        elsif ($self->is_latex) {
            return "\\hyperref{}{amuse}{$linkname}{$desc}";
        }
    }

    if ($self->is_html) {
        $link = $self->_url_safe_escape($link);
        return qq{<a class="text-amuse-link" href="$link">$desc</a>};
    }
    elsif ($self->is_latex) {
        return qq/\\href{/ .
          $self->_url_safe_escape($link) .
            qq/}{$desc}/;
    }
    else { die "Not reached" }
}

=head3 format_single_link

=cut

sub format_single_link {
    my ($self, $link) = @_;
    # the re matches only clean names, no need to escape anything
    if (my $image = $self->find_image($link)) {
        $self->document->attachments($image->filename);
        return $image->output;
    }
    if ($link =~ m/\A\#([A-Za-z][A-Za-z0-9]+)\z/) {
        my $linkname = $1;
        # link is sane and safe
        if ($self->is_html) {
            $link = "#text-amuse-label-$linkname";
            return qq{<a class="text-amuse-link" href="$link">$linkname</a>};
        }
        elsif ($self->is_latex) {
            return "\\hyperref{}{amuse}{$linkname}{$linkname}";
        }
    }
    if ($self->is_html) {
        $link = $self->_url_safe_escape($link);
        return qq{<a class="text-amuse-link" href="$link">$link</a>};
    }
    elsif ($self->is_latex) {
        return "\\url{" . $self->_url_safe_escape($link) . "}";
    }
    else { die "Not reached" }
}

=head3 _url_safe_escape

=cut

sub _url_safe_escape {
  my ($self, $string) = @_;
  utf8::encode($string);
  $string =~ s/([^0-9a-zA-Z\.\/\:\;_\%\&\#\?\=\-])
	      /sprintf("%%%02X", ord ($1))/gesx;
  my $escaped = $self->safe($string);
  return $escaped;
}

=head1 HELPERS

Methods providing some fixed values

=cut

=head3 blk_table

=cut

sub blk_table {
    my $self = shift;
    unless ($self->{_block_table_map}) {
        $self->{_block_table_map} = $self->_build_blk_table;
    }
    return $self->{_block_table_map};
}

sub _build_blk_table {
    my $table = {
                                  p =>  { start => {
                                                    ltx => "\n",
                                                    html => "\n<p>\n",
                                                   },
                                          stop => {
                                                   ltx => "\n\n",
                                                   html => "\n</p>\n",
                                                  },
                                        },
                                  h1 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(part => @_);
                                                   },
                                                   html => "<h2>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h2>\n"
                                                 }
                                        },
                                  h2 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(chapter => @_);
                                                   },
                                                   html => "<h3>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h3>\n"
                                                 }
                                        },
                                  h3 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(section => @_);
                                                   },
                                                   html => "<h4>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h4>\n"
                                                 }
                                        },
                                  h4 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(subsection => @_);
                                                   },
                                                   html => "<h5>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h5>\n"
                                                 }
                                        },
                                  h5 => {
                                         start => {
                                                   ltx => sub {
                                                       _latex_header(subsubsection => @_);
                                                   },
                                                   html => "<h6>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h6>\n"
                                                 }
                                        },
                                  example => { 
                                              start => { 
                                                        html => "\n<pre class=\"example\">\n",
                                                        ltx => "\n\\begin{alltt}\n",
                                                       },
                                              stop => {
                                                       html => "</pre>\n",
                                                       ltx => "\\end{alltt}\n\n",
                                                      },
                                             },
                                  
                                  comment => {
                                              start => { # we could also use a more
                                                        # stable startstop hiding
                                                        html => "\n<!-- start comment -->\n<div class=\"comment\"><span class=\"commentmarker\">{{COMMENT:</span> \n",
                                                        ltx => "\n\n\\begin{comment}\n",
                                                       },
                                              stop => {
                                                       html => "\n<span class=\"commentmarker\">END_COMMENT}}:</span>\n</div>\n<!-- stop comment -->\n",  
                                                       ltx => "\n\\end{comment}\n\n",
                                                      },
                                             },
                                  verse => {
                                            start => {
                                                      html => "<div class=\"verse\">\n",
                                                      ltx => "\n\n\\begin{verse}\n",
                                                     },
                                            stop => {
                                                     html => "\n</div>\n",
                                                     ltx => "\n\\end{verse}\n\n",
                                                    },
                                           },
                               quote => {
                                         start => {
                                                   html => "\n<blockquote>\n",
                                                   ltx => "\n\n\\begin{quote}\n\n",
                                                  },
                                         stop => {
                                                  html => "\n</blockquote>\n",
                                                  ltx => "\n\n\\end{quote}\n\n",
                                                 },
                                        },
	      
                               biblio => {
                                          start => {
                                                    html => "\n<div class=\"biblio\">\n",
                                                    ltx => "\n\n\\begin{amusebiblio}\n\n",
                                                   },
                                          stop => {
                                                   html => "\n</div>\n",
                                                   ltx => "\n\n\\end{amusebiblio}\n\n",
                                                  },
                                         },
                               play => {
                                        start => {
                                                  html => "\n<div class=\"play\">\n",
                                                  ltx => "\n\n\\begin{amuseplay}\n\n",
                                                 },
                                        stop => {
                                                 html => "\n</div>\n",
                                                 ltx => "\n\n\\end{amuseplay}\n\n",
                                                },
                                       },

                               center => {
                                          start => {
                                                    html => "\n<div class=\"center\">\n",
                                                    ltx => "\n\n\\begin{center}\n",
                                                   },
                                          stop => {
                                                   html => "\n</div>\n",
                                                   ltx => "\n\\end{center}\n\n",
                                                  },
                                         },
                               right => {
                                         start => {
                                                   html => "\n<div class=\"right\">\n",
                                                   ltx => "\n\n\\begin{flushright}\n",
                                                  },
                                         stop => {
                                                  html => "\n</div>\n",
                                                  ltx => "\n\\end{flushright}\n\n",
                                                 },
                                        },

                               ul => {
                                      start => {
                                                html => "\n<ul>\n",
                                                ltx => "\n\\begin{itemize}\n",
                                               },
                                      stop => {
                                               html => "\n</ul>\n",
                                               ltx => "\n\\end{itemize}\n",
                                              },
                                     },

                               ol => {
                                      start => {
                                                html => sub {
                                                    _html_ol_element(n => @_);
                                                },
                                                ltx => sub {
                                                    _ltx_enum_element(1 => @_);
                                                },
                                               },
                                      stop => {
                                               html => "\n</ol>\n",
                                               ltx => "\n\\end{enumerate}\n",
                                              },
                                     },

                               oln => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(n => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(1 => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               oli => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(i => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(i => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               olI => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(I => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(I => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               olA => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(A => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(A => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               ola => {
                                       start => {
                                                 html => sub {
                                                     _html_ol_element(a => @_);
                                                 },
                                                 ltx => sub {
                                                     _ltx_enum_element(a => @_);
                                                 },
                                                },
                                       stop => {
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               li => {
                                      start => {
                                                html => "<li>",
                                                ltx => "\\item\\relax ",
                                               },
                                      stop => {
                                               html => "\n</li>\n",
                                               ltx => "\n\n",
                                              },
                                     },
                 dl => {
                        start => {
                                  ltx => "\n\\begin{description}\n",
                                  html => "\n<dl>\n",
                                 },
                        stop => {
                                 ltx => "\n\\end{description}\n",
                                 html => "\n</dl>\n",
                                },
                       },
                 dt => {
                        start => {
                                  ltx => "\n\\item[{",
                                  html => "<dt>",
                                 },
                        stop => {
                                 ltx => "}] ",
                                 html => "</dt>",
                                },
                       },
                 dd => {
                        start => {
                                  ltx => "",
                                  html => "\n<dd>",
                                 },
                        stop => {
                                 ltx => "",
                                 html => "</dd>\n",
                                },
                       },
                };
    return $table;
}


=head3 image_re

Regular expression to match image links.

=cut

sub image_re {
    return qr{([0-9A-Za-z][0-9A-Za-z/-]+ # basename
                                    \. # dot
                                    (png|jpe?g)) # extension $2
                                ([ ]+
                                    ([0-9]+)? # width in percent
                                    ([ ]*([rlf]))?
                                )?}x;
}


=head3 find_image($link)

Given the input string $link, return undef if it's not an image. If it
is, return a Text::Amuse::Output::Image object.

=cut

sub find_image {
    my ($self, $link) = @_;
    my $imagere = $self->image_re;
    if ($link =~ m/^$imagere$/s) {
        my $filename = $1;
        my $width = $4;
        my $float = $6;
        return Text::Amuse::Output::Image->new(filename => $filename,
                                               width => $width,
                                               wrap => $float,
                                               fmt => $self->fmt);
    }
    else {
        # warn "Not recognized\n";
        return;
    }
}


=head3 url_re

=cut

sub url_re {
    return qr!((www\.|https?:\/\/)
                              \w[\w\-\.]+\.\w+ # domain
                              (:\d+)? # the port
                              # everything else, but start with a
                              # slash and end with a a \w, and don't
                              # tolerate spaces
                              (/(\S*\w)?)?)
                             !x;
}


=head3 html_table_mapping

=cut

sub html_table_mapping {
    return {
            head => {
                     b => " <thead>",
                     e => " </thead>",
                     bcell => "   <th>",
                     ecell => "   </th>",
                    },
            foot => {
                     b => " <tfoot>",
                     e => " </tfoot>",
                     bcell => "   <td>",
                     ecell => "   </td>",
                    },
            body => {
                     b => " <tbody>",
                     e => " </tbody>",
                     bcell => "   <td>",
                     ecell => "   </td>",
                    },
            btr => "  <tr>",
            etr => "  </tr>",
           };
}

sub _html_ol_element {
    my ($type, %attributes) = @_;
    my %map = (
               ol => '',
               n => '',
               i => 'lower-roman',
               I => 'upper-roman',
               A => 'upper-alpha',
               a => 'lower-alpha',
              );
    my $ol_type = '';
    if ($map{$type}) {
        $ol_type = qq{ style="list-style-type:$map{$type}"};
    }
    my $start = $attributes{start_list_index};
    my $start_string = '';
    if ($start and $start =~ m/\A[0-9]+\z/ and $start > 1) {
        $start_string = qq{ start="$start"};
    }
    return "\n<ol" . $ol_type . $start_string . ">\n";
}

sub _ltx_enum_element {
    my ($type, %attributes) = @_;
    my %map = (
               1 => '1',
               i => 'i',
               I => 'I',
               A => 'A',
               a => 'a',
              );
    my $string = "\n\\begin{enumerate}[";
    my $type_string = $map{$type} || '1';

    my $start = $attributes{start_list_index};
    my $start_string = '';
    if ($start and $start =~ m/\A[0-9]+\z/ and $start > 1) {
        $start_string = qq{, start=$start};
    }
    return $string . $type_string . '.' . $start_string . "]\n";
}

sub _latex_header {
    # All sectioning commands take the same general form, e.g.,
    # \chapter[TOCTITLE]{TITLE}
    my ($name, %attributes) = @_;
    if (defined $attributes{toc_entry}) {
        # we use the grouping here, to avoid chocking on [ ]
        return "\\" . $name . '[{' . $attributes{toc_entry} . '}]{'
    }
    else {
        return "\\" . $name . '{';
    }
}

1;
