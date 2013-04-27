package Text::AMuse::Output;
use strict;
use warnings;
use utf8;

=head2 Basic LaTeX preamble

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

% avoid breakage on multiple <br><br> and avoid the next [] to be eaten
\newcommand*{\forcelinebreak}{~\\\relax}

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
}{\bigskip}

\newenvironment{amuseplay}{
  \leftskip=\parindent
  \parindent=-\parindent
  \bigskip
}{\bigskip}





=cut





sub new {
    my $class = shift;
    my %opts = @_;
    die "Missing document object!\n" unless $opts{document};
    my $self = \%opts;
    bless $self, $class;
}

sub document {
    return shift->{document};
}

sub add_footnote {
    my ($self, $num) = @_;
    return unless $num;
    unless ($self->document->get_footnote($num)) {
        warn "no footnote $num found!";
        return;
    }
    unless (defined $self->{_fn_list}) {
        $self->{_fn_list} = [];
    }
    push @{$self->{_fn_list}}, $num;
}

sub flush_footnotes {
    my $self = shift;
    return unless (defined $self->{_fn_list});
    return @{$self->{_fn_list}};
}

=head3 process ($type)

Return the string for format C<$type>, where $type can be "ltx" or
"html".

=cut


sub process {
    my ($self, $format) = @_;
    my @pieces;
    # loop over the parsed elements
    foreach my $el ($self->document->document) {
        if ($el->type eq 'startblock') {
            die "startblock with string passed!: " . $el->string if $el->string;
            push @pieces, $self->blkstring(start => $format => $el->block);
        }
        elsif ($el->type eq 'stopblock') {
            die "stopblock with string passed!:" . $el->string if $el->string;
            push @pieces, $self->blkstring(stop => $format => $el->block);
        }
        elsif ($el->type eq 'regular') {
            push @pieces, $self->manage_paragraph($format => $el);
        }
        elsif ($el->type =~ m/h[1-6]/) {
            push @pieces, $self->manage_header($format => $el);
        }
        elsif ($el->type eq 'verse') {
            push @pieces, $self->manage_verse($format => $el);
        }
        elsif ($el->type eq 'comment') {
            push @pieces, $self->manage_comment($format => $el);
        }
        elsif ($el->type eq 'table') {
            push @pieces, $self->manage_table($format => $el);
        }
        elsif ($el->type eq 'example') {
            push @pieces, $self->manage_example($format => $el);
        }
        else {
            die "Unrecognized element: " . Dumper($el);
        }
    }
    if ($format eq 'html') {
        foreach my $fn ($self->flush_footnotes) {
            push @pieces, $self->manage_html_footnote($fn);
        }
    }
    return join("", @pieces);
}

sub manage_html_footnote {
    my ($self, $num) = @_;
    return unless $num;
    my $chunk = qq{\n<p class="fnline"><a class="footnotebody"} . " "
      . qq{href="#fn_back$num" id="fn$num">[$num]</a> } .
        $self->manage_regular(html => $self->document->get_footnote($num)) .
          qq{</p>\n};
}


sub blkstring {
    my ($self, @args) = @_;
    return $self->_get_block_string(@args, $self->blk_table);
}

sub _get_block_string {
    my ($self, $start_stop, $format, $block, $table) = @_;
    die "Wrong usage! Missing params $start_stop, $format, $block, $table\n"
      unless ($start_stop && $format && $block && $table);
    die "Wrong usage!\n" unless ($start_stop eq 'stop' or
                                 $start_stop eq 'start');
    die "Wrong usage!\n" unless ($format eq 'ltx' or
                                 $format eq 'html');
    die "Table is missing an element $start_stop $format $block "
      unless exists $table->{$block}->{$start_stop}->{$format};
    return $table->{$block}->{$start_stop}->{$format};
}


sub manage_regular {
    my ($self, $format, $el) = @_;
    my $string;
    my $recurse = 1;
    # we can accept even plain string;
    if (ref($el) eq "") {
        $string = $el;
    } else {
        $string = $el->string;
        if ($el->type eq 'footnote') {
            $recurse = 0;
        }
    }
    return "" unless defined $string;
    my $linkre = $self->link_re;
    # split at [[ ]] to avoid the mess
    my @pieces = split /($linkre)/, $string;
    my @out;
    while (@pieces) {
        my $l = shift @pieces;
        if ($l =~ m/^$linkre$/s) {
            push @out, $self->linkify_links($format, $l);
        } else {
            next if $l eq ""; # no text!

            # convert the muse markup to tags
            $l = $self->muse_inline_syntax_to_tags($l);

            # here we have different routines
            if ($format eq 'ltx') {
                $l = $self->escape_tex($l);
                $l = $self->tex_replace_ldots($l);
                $l = $self->muse_inline_syntax_to_ltx($l);
            }
            elsif ($format eq 'html') {
                $l = $self->escape_html($l);
            }
            else {
                die "Wrong format $format for $l in manage_regular\n";
            }
        }
        if ($recurse) {
            $l = $self->inline_footnotes($format, $l);
        }
        push @out, $l;
    }
    return join("", @out);
}

sub inline_footnotes {
    my $self = shift;
    my ($format, $string) = @_;
    my @output;
    die "Wrong format $format" unless ($format eq 'ltx' or
                                       $format eq 'html');
    my $footnotere = $self->footnote_re;
    return $string unless $string =~ m/($footnotere)/;
    my @pieces = split /( *$footnotere)/, $string;
    while (@pieces) {
        my $piece = shift @pieces;
        if ($piece =~ m/^( *)\[([0-9]+)\]$/s) {
            my $space = $1 || "";
            my $fn_num = $2;
            my $footnote = $self->document->get_footnote($fn_num);
            # here we have a bit of recursion, but it should be safe
            if (defined $footnote) {
                $footnote = $self->manage_regular($format, $footnote);
                if ($format eq "ltx") {
                    $footnote =~ s/\n/ /gs;
                    $footnote =~ s/ +$//s;
                    push @output, '\footnote{' . $footnote . '}';
                }
                elsif ($format eq "html") {
                    # in html, just remember the number
                    $self->add_footnote($fn_num);
                    push @output,
                      qq{$space<a href="#fn${fn_num}" class="footnote" } .
                        qq{id="fn_back${fn_num}">[$fn_num]</a>};
                }
                else {
                    die "unknow type $format";
                }
            }
            else {
                warn "Missing footnote [$fn_num] in $string";
                push @output, $piece;
            }
        }
        else {
            push @output, $piece;
        }
    }
    return join("", @output);
}

sub safe {
    my ($self, $format, $string) = @_;
    if ($format eq 'ltx') {
        return $self->escape_tex($string);
    }
    elsif ($format eq 'html') {
        return $self->escape_all_html($string);
    }
    else {
        die "Wtf?"
    }
}

sub escape_tex {
    my ($self, $string) = @_;
    $string =~ s/\\/\\textbackslash{}/g;
    $string =~ s/#/\\#/g ;
    $string =~ s/\$/\\\$/g;
    $string =~ s/%/\\%/g;
    $string =~ s/&/\\&/g;
    $string =~ s/_/\\_/g ;
    $string =~ s/{/\\{/g ;
    $string =~ s/}/\\}/g ;
    $string =~ s/\\textbackslash\\{\\}/\\textbackslash{}/g;
    $string =~ s/~/\\textasciitilde{}/g ;
    $string =~ s/\^/\\^{}/g ;
    $string =~ s/\|/\\textbar{}/g;
    return $string;
}

sub tex_replace_ldots {
    my ($self, $string) = @_;
    my $ldots = "\\dots{}";
    $string =~ s/\.{3,4}/$ldots/g ;
    $string =~ s/\x{2026}/$ldots/g;
    return $string;
}


sub escape_all_html {
    my ($self, $string) = @_;
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/"/&quot;/g;
    $string =~ s/'/&#x27;/g;
    return $string;
}

sub muse_inline_syntax_to_ltx {
    my ($self, $string) = @_;
    $string =~ s!<strong>(.+?)</strong>!\\textbf{$1}!gs;
    $string =~ s!<em>(.+?)</em>!\\emph{$1}!gs;
    $string =~ s!<code>(.+?)</code>!\\texttt{$1}!gs;
    # the same
    $string =~ s!<strike>(.+?)</strike>!\\sout{$1}!gs;
    $string =~ s!<del>(.+?)</del>!\\sout{$1}!gs;
    $string =~ s!<sup>(.+?)</sup>!\\textsuperscript{$1}!gs;
    $string =~ s!<sub>(.+?)</sub>!\\textsubscript{$1}!gs;
    $string =~ s!^[\s]*<br ?/?>[\s]*$!\n\\bigskip\n!gm;
    $string =~ s!<br ?/?>!\\forcelinebreak !gs;
    return $string;
}

sub escape_html {
    my ($self, $string) = @_;
    $string = $self->remove_permitted_html($string);
    $string = $self->escape_all_html($string);
    $string = $self->restore_permitted_html($string);
    return $string;
}

sub remove_permitted_html {
    my ($self, $string) = @_;
    foreach my $tag (keys %{ $self->tag_hash }) {
        # only matched pairs, so we avoid a lot of problems
        # we also use private unicode codepoints to mark start and end
        my $marker = $self->tag_hash->{$tag};
        my $startm = "\x{f0001}${marker}\x{f0002}";
        my $stopm  = "\x{f0003}${marker}\x{f0004}";
        $string =~ s!<$tag>
                     (.*?)
                     </$tag>
                    !$startm$1$stopm!gsx;
    };
    my $brhash = $self->br_hash;
    $string =~ s!<br */*>!\x{f0001}$brhash\x{f0002}!gs;
    return $string;
}

sub restore_permitted_html {
    my ($self, $string) = @_;
    foreach my $hash (keys %{ $self->reverse_tag_hash }) {
        my $orig = $self->reverse_tag_hash->{$hash};
        $string =~ s!\x{f0001}$hash\x{f0002}!<$orig>!gs;
        $string =~ s!\x{f0003}$hash\x{f0004}!</$orig>!gs;
    }
    my $brhash = $self->br_hash;
    $string =~ s!\x{f0001}$brhash\x{f0002}!<br />!gs;
    return $string;
}



sub muse_inline_syntax_to_tags {
    my ($self, $string) = @_;
    # first, add a space around, so we don't need to check for ^ and $
    $string = " " . $string . " ";
    # the *, something not a space, the match (no * inside), something
    # not a space, the *
    my $something = qr{\*(?=\S)([^\*]+?)(?<=\S)\*};
    # the same, but for =
    my $somethingeq = qr{\=(?=\S)([^\=]+?)(?<=\S)\=};

    # before and after the *, something not a word and not an *
    $string =~ s{(?<=[^\*\w])\*\*
                 $something
                 \*\*(?=[^\*\w])}
                {<strong><em>$1</em></strong>}gsx;
    $string =~ s{(?<=[^\*\w])\*
                 $something
                 \*(?=[^\*\w])}
                {<strong>$1</strong>}gsx;
    $string =~ s{(?<=[^\*\w])
                 $something
                 (?=[^\*\w])}
                {<em>$1</em>}gsx;
    $string =~ s{(?<=[^\=\w])
                 $somethingeq
                 (?=[^\=\w])}
                {<code>$1</code>}gsx;
    # the full line without the 2 spaces added;
    my $l = (length $string) - 2;
    # return the string, starting from 1 and for the length of the string.
    return substr($string, 1, $l);
}


sub manage_paragraph {
    my ($self, $format, $el) = @_;
    my $body = $self->manage_regular($format, $el);
    chomp $body;
    return $self->blkstring(start => $format => "p") .
      $body . $self->blkstring(stop => $format => "p");
}

sub manage_header {
    my ($self, $format, $el) = @_;
    my $body = $self->manage_regular($format, $el);
    # remove trailing spaces and \n
    chomp $body;
    return $self->blkstring(start => $format => $el->type) .
      $body .
        $self->blkstring(stop => $format => $el->type) . "\n";
}

sub manage_verse {
    my ($self, $format, $el) = @_;
    my ($lead, $eol, $stanzasep);
    if ($format eq 'html') {
        $lead = "&nbsp;";
        $eol = "<br />\n";
        $stanzasep = "\n<br /><br />\n";
    }
    elsif ($format eq 'ltx') {
        $lead = "~";
        $eol = "\\forcelinebreak\n";
        $stanzasep = "\n\n";
    }
    else {
        die "wtf $format?";
    }
    my @stanza;
    my @out;
    my (@chunks) = split(/\n/, $el->string);
    foreach my $l (@chunks) {
        if ($l =~ m/^( *)(.+?)$/s) {
            my $leading = $lead x length($1);
            my $text = $self->manage_regular($format => $2);
            push @stanza, $leading . $text;
        }
        elsif ($l =~ m/^\s*$/s) {
            if (@stanza) {
                push @out, join($eol, @stanza);
                @stanza = ();
            }
        }
        else {
            die "wtf?";
        }
    }
    # flush the stanzas
    if (@stanza) {
        push @out, join($eol, @stanza);
    }
    # process
    return $self->blkstring(start => $format => $el->type) .
      join($stanzasep, @out) . $self->blkstring(stop => $format => $el->type);
}

sub manage_comment {
    my ($self, $format, $el) = @_;
    my $body = $self->safe($format => $el->removed);
    chomp $body;
    return $self->blkstring(start => $format => $el->type) .
      $body . $self->blkstring(stop => $format => $el->type);
}

sub manage_table {
    my ($self, $format, $el) = @_;
    my $thash = $self->_split_table_in_hash($el->string);
    if ($format eq 'html') {
        return $self->manage_table_html($thash);
    }
    elsif ($format eq 'ltx') {
        return $self->manage_table_ltx($thash);
    }
    else {
        die "wtf?"
    }
}

sub manage_table_html {
    my ($self, $table) = @_;
    my @out;
    my $map = $self->html_table_mapping;
    # here it's full of hardcoded things, but it can't be done differently
    push @out, "\n<table>";

    # the hash is always defined
    if ($table->{caption} ne "") {
        push @out, "<caption>"
          . $self->manage_regular(html => $table->{caption})
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
                  $self->manage_regular(html => $cell),
                    $map->{$tablepart}->{ecell},
                }
            push @out, $map->{etr};
        }
        push @out, $map->{$tablepart}->{e};
    }
    push @out, "</table>\n";
    return join("\n", @out);
}

sub manage_table_ltx {
    my ($self, $table) = @_;

    my $total = 0;
    my $out = {
               body => [],
               head => [],
               foot => [],
              };
    foreach my $t (qw/body head foot/) {
        foreach my $rt (@{$table->{$t}}) {
            my @row;
            # update the counter
            if (@$rt > $total) {
                $total = scalar @$rt;
            }
            foreach my $cell (@$rt) {
                # escape all!
                push @row, $self->manage_regular(ltx => $cell);
            }
            my $texrow = join(q{ & }, @row);
            push @{$out->{$t}}, $texrow . "  \\\\\n"
        }
    }
    # then we loop over what we have. First head, then body, and
    # finally foot print "found $total fields\n";
    
    my $textable = "\\begin{table}[htp]\n\\centering\n\\begin{tabular}{" ;
      $textable .= "|c" x $total; $textable .= "|}\n";
    if (my @head = @{$out->{head}}) {
        $textable .= "\\hline\n" . join("", @head);
    }
    if (my @body = @{$out->{body}}) {
        $textable .= "\\hline\n" . join("", @body);
    }
    if (my @foot = @{$out->{foot}}) {
        $textable .= "\\hline\n" . join("", @foot);
    }
    $textable .= "\\hline\n\\end{tabular}\n";
    if (my $caption = $table->{caption}) {
        $textable .= "\n" . $caption . "\n\n";
    }
    $textable .= "\\end{table}\n";
    # print $textable;
    return $textable;
}




sub _split_table_in_hash {
    my ($self, $table) = @_;
    return {} unless $table;
    my $output = {
                  "caption" => "",
                  "body" => [],
                  "head" => [],
                  "foot" => [],
                 };
    foreach my $row (split "\n", $table) {
        if ($row =~ m/^\s*\|\+\s*(.+?)\s*\+\|\s*$/) {
            $output->{caption} = $1;
            next
        }
        # clean up the chunk
        $row =~ s/^\s*\|+(.+?)\|+\s*$/$1/gm;
        if ($row =~ m/\|\|\|/) {
            my @fcells = split /\|+/, $row;
            push @{$output->{foot}}, \@fcells;
        } elsif ($row =~ m/\|\|/) {
            my @hcells = split /\|+/, $row;
            push @{$output->{head}}, \@hcells;
        } else {
            my @cells = split /\|+/, $row;
            push @{$output->{body}}, \@cells;
        }
    }
    return $output;
}


sub manage_example {
    my ($self, $format, $el) = @_;
    my $body = $self->safe($format => $el->string);
    return $self->blkstring(start => $format => $el->type) .
      $body . $self->blkstring(stop => $format => $el->type);
}


=head1 HELPERS

Methods providing some fixed values

=cut


sub blk_table {
    my $self = shift;
    unless (defined $self->{_blk_table}) {
        $self->{_blk_table} = {
                                  p =>  { start => {
                                                    ltx => "\n",
                                                    html => "\n<p>",
                                                   },
                                          stop => {
                                                   ltx => "\n\n",
                                                   html => "</p>\n",
                                                  },
                                        },
                                  h1 => {
                                         start => {
                                                   ltx => "\\part{",
                                                   html => "<h2>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h2>\n"
                                                 }
                                        },
                                  h2 => {
                                         start => {
                                                   ltx => "\\chapter{",
                                                   html => "<h3>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h3>\n"
                                                 }
                                        },
                                  h3 => {
                                         start => {
                                                   ltx => "\\section{",
                                                   html => "<h4>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h4>\n"
                                                 }
                                        },
                                  h4 => {
                                         start => {
                                                   ltx => "\\subsection{",
                                                   html => "<h5>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h5>\n"
                                                 }
                                        },
                                  h5 => {
                                         start => {
                                                   ltx => "\\subsubsection{",
                                                   html => "<h6>",
                                                  },
                                         stop => {
                                                  ltx => "}\n",
                                                  html => "</h6>\n"
                                                 }
                                        },
                                  example => { 
                                              start => { 
                                                        tex => "{\n\\startlines[space=on,style=\\tt]\n",
                                                        html => "\n<pre class=\"example\">\n",
                                                        ltx => "\n\\begin{alltt}\n",
                                                       },
                                              stop => {
                                                       tex => "\n\\stoplines\n",
                                                       html => "\n</pre>\n",
                                                       ltx => "\n\\end{alltt}\n\n",
                                                      },
                                             },
                                  
                                  comment => {
                                              start => { # we could also use a more
                                                        # stable startstop hiding
                                                        tex => "\n\\startcomment[][]\n",
                                                        html => "\n<!-- start comment -->\n<div class=\"comment\"><span class=\"commentmarker\">{{COMMENT:</span> \n",
                                                        ltx => "\n\n\\begin{comment}\n",
                                                       },
                                              stop => {
                                                       tex => "\n\\stopcomment\n",
                                                       html => "\n<span class=\"commentmarker\">END_COMMENT}}:</span>\n</div>\n<!-- stop comment -->\n",  
                                                       ltx => "\n\\end{comment}\n\n",
                                                      },
                                             },
                                  verse => {
                                            start => {
                                                      tex => "\n\n\\startawikiverse\n",
                                                      html => "<div class=\"verse\">\n",
                                                      ltx => "\n\n\\begin{verse}\n",
                                                     },
                                            stop => {
                                                     tex => "\\stopawikiverse\n\n",
                                                     html => "\n</div>\n",
                                                     ltx => "\n\\end{verse}\n\n",
                                                    },
                                           },
                               quote => {
                                         start => {
                                                   tex => "\n\\startblockquote\n",
                                                   html => "\n<blockquote>\n",
                                                   ltx => "\n\n\\begin{quote}\n\n",
                                                  },
                                         stop => {
                                                  tex => "\n\\stopblockquote\n",
                                                  html => "</blockquote>\n",
                                                  ltx => "\n\n\\end{quote}\n\n",
                                                 },
                                        },
	      
                               biblio => {
                                          start => {
                                                    tex => "\\startawikibiblio\n",
                                                    html => "<div class=\"biblio\">\n",
                                                    ltx => "\n\n\\begin{amusebiblio}\n\n",
                                                   },
                                          stop => {
                                                   tex => "\\stopawikibiblio\n",
                                                   html => "</div>\n",
                                                   ltx => "\n\n\\end{amusebiblio}\n\n",
                                                  },
                                         },
                               play => {
                                        start => {
                                                  tex => "\\startawikiplay\n",
                                                  html => "<div class=\"play\">\n",
                                                  ltx => "\n\n\\begin{amuseplay}\n\n",
                                                 },
                                        stop => {
                                                 tex => "\\stopawikiplay\n",
                                                 html => "</div>\n",
                                                 ltx => "\n\n\\end{amuseplay}\n\n",
                                                },
                                       },

                               center => {
                                          start => {
                                                    tex => "\\startawikicenter\n",
                                                    html => "<div class=\"center\">",
                                                    ltx => "\n\n\\begin{center}\n",
                                                   },
                                          stop => {
                                                   tex => "\\stopawikicenter\n",
                                                   html => "</div>",
                                                   ltx => "\n\\end{center}\n\n",
                                                  },
                                         },
                               right => {
                                         start => {
                                                   tex => "\\startawikiright\n",
                                                   html => "<div class=\"right\">",
                                                   ltx => "\n\n\\begin{flushright}\n",
                                                  },
                                         stop => {
                                                  tex => "\\stopawikiright\n",
                                                  html => "</div>",
                                                  ltx => "\n\\end{flushright}\n\n",
                                                 },
                                        },

                               ul => {
                                      start => {
                                                tex => "\n\\startitemize[1]\\relax\n",
                                                html => "\n<ul>\n",
                                                ltx => "\n\\begin{itemize}\n",
                                               },
                                      stop => {
                                               tex => "\n\\stopitemize\n",
                                               html => "\n</ul>\n",
                                               ltx => "\n\\end{itemize}\n",
                                              },
                                     },


                               ol => {
                                      start => {
                                                tex => "\n\\startitemize[N]\\relax\n",
                                                html => "\n<ol>\n",
                                                ltx => "\n\\begin{enumerate}[1.]\n",
                                               },
                                      stop => {
                                               tex => "\n\\stopitemize\n",
                                               html => "\n</ol>\n",
                                               ltx => "\n\\end{enumerate}\n",
                                              },
                                     },

                               oln => {
                                       start => {
                                                 tex => "\n\\startitemize[N]\\relax\n",
                                                 html => "\n<ol>\n",
                                                 ltx => "\n\\begin{enumerate}[1.]\n",
                                                },
                                       stop => {
                                                tex => "\n\\stopitemize\n",
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },


                               oli => {
                                       start => {
                                                 tex => "\n\\startitemize[r]\\relax\n",
                                                 html => "\n<ol style=\"list-style-type:lower-roman\">\n",
                                                 ltx => "\n\\begin{enumerate}[i.]\n",
                                                },
                                       stop => {
                                                tex => "\n\\stopitemize\n",
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               olI => {
                                       start => {
                                                 tex => "\n\\startitemize[R]\\relax\n",
                                                 html => "\n<ol style=\"list-style-type:upper-roman\">\n",
                                                 ltx => "\n\\begin{enumerate}[I.]\n",
                                                },
                                       stop => {
                                                tex => "\n\\stopitemize\n",
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               olA => {
                                       start => {
                                                 tex => "\n\\startitemize[A]\\relax\n",
                                                 html => "\n<ol style=\"list-style-type:upper-alpha\">\n",
                                                 ltx => "\n\\begin{enumerate}[A.]\n",
                                                },
                                       stop => {
                                                tex => "\n\\stopitemize\n",
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },


                               ola => {
                                       start => {
                                                 tex => "\n\\startitemize[a]\\relax\n",
                                                 html => "\n<ol style=\"list-style-type:lower-alpha\">\n",
                                                 ltx => "\n\\begin{enumerate}[a.]\n",
                                                },
                                       stop => {
                                                tex => "\n\\stopitemize\n",
                                                html => "\n</ol>\n",
                                                ltx => "\n\\end{enumerate}\n",
                                               },
                                      },

                               li => {
                                      start => {
                                                tex => "\\item[] ",
                                                html => "<li>",
                                                ltx => "\\item\\relax ",
                                               },
                                      stop => {
                                               tex => "\n\n ",
                                               html => "\n</li>\n",
                                               ltx => "\n\n",
                                              },
                                     },
                              };
    }
    return $self->{_blk_table}
}




sub link_re {
    my $self = shift;
    unless (defined $self->{_link_re}) {
        $self->{_link_re} = qr{\[\[[^\[].*?\]\]};
    }
    return $self->{_link_re};
}

sub image_re {
    my $self = shift;
    unless (defined $self->{_image_re}) {
        $self->{_image_re} = qr{([0-9a-zA-Z/-]+\.(png|jpe?g))};
    }
    return $self->{_image_re};
}

sub url_re {
    my $self = shift;
    unless (defined $self->{_url_re}) {
        $self->{_url_re} = qr!((www\.|https?:\/\/)
                              \w[\w\-\.]+\.\w+ # domain
                              (:\d+)? # the port
                              # everything else, but start with a
                              # slash and end with a a \w, and don't
                              # tolerate spaces
                              (/(\S*\w)?)?)
                             !x;
    }
    return $self->{_url_re};
}

sub footnote_re {
    my $self = shift;
    unless (defined $self->{_footnote_re}) {
        $self->{_footnote_re} = qr{\[[0-9]+\]};
    }
    return $self->{_footnote_re};
}

sub br_hash {
    my $self = shift;
    unless (defined $self->{_br_hash}) {
        $self->{_br_hash} = '49777d285f86e8b252431fdc1a78b92459704911';
    }
    return $self->{_br_hash};
}

sub tag_hash {
    my $self = shift;
    unless (defined $self->{_tag_hash}) {
        $self->{_tag_hash} =
          {
           'em' => '93470662f625a56cd4ab62d9d820a77e6468638e',
           'sub' => '5d85613a56c124e3a3ff8ce6fc95d10cdcb5001e',
           'del' => 'fea453f853c8645b085126e6517eab38dfaa022f',
           'strike' => 'afe5fd4ff1a85caa390fd9f36005c6f785b58cb4',
           'strong' => '0117691d0201f04aa02f586b774c190802d47d8c',
           'sup' => '3844b17b367801f41a3ff27aab7d5ca297c2b984',
           'code' => 'e6fb06210fafc02fd7479ddbed2d042cc3a5155e',
          };
    }
    return $self->{_tag_hash};
}

sub reverse_tag_hash {
    my $self = shift;
    unless (defined $self->{_reverse_tag_hash}) {
        my %hash = %{ $self->tag_hash };
        my %reverse = reverse %hash;
        $self->{_reverse_tag_hash} = \%reverse;
    }
    return $self->{_reverse_tag_hash};
}


sub html_table_mapping {
    my $self = shift;
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

1;
