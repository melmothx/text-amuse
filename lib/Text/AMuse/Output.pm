package Text::AMuse::Output;
use strict;
use warnings;
use utf8;

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
            push @pieces, $self->manage_regular($format => $el);
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
        # flush the footnotes, which are not embedded in the lines
    }
    return join("", @pieces);
}


sub blkstring {
    my ($self, @args) = @_;
    return $self->_get_block_string(@args, $self->blk_table);
}

sub inlineblk {
    my ($self, @args) = @_;
    return $self->_get_block_string(@args, $self->inline_table);
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
    # we can accept even plain string;
    if (ref($el) eq "") {
        $string = $el;
    } else {
        $string = $el->string
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
        $l = $self->inline_footnotes($format, $l);
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
                    push @output,
                      "$space<a href=\"#fn${fn_num}\"". " "
                        . "class=\"footnote\"" . " "
                          . "id=\"fn_back${fn_num}\"" . ">["
                            . $fn_num . "]</a>";
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


sub manage_header {
    my ($self, $format, $el) = @_;
    my $body = $self->manage_regular($format, $el);
    # remove trailing spaces and \n
    chomp $body;
    return $self->inlineblk(start => $format => $el->type) .
      $body .
        $self->inlineblk(stop => $format => $el->type) . "\n";
}

sub manage_verse {
    my ($self, $format, $el) = @_;
    my $body = $el->string;
    # process
    return $self->inlineblk(start => $format => $el->type) .
      $body . $self->inlineblk(stop => $format => $el->type);
}

sub manage_comment {
    my ($self, $format, $el) = @_;
    my $body = $el->removed;
    return $self->inlineblk(start => $format => $el->type) .
      $body . $self->inlineblk(stop => $format => $el->type);
}

sub manage_table {
    my ($self, $format, $el) = @_;
    my $body = $el->string;
    # process
    return "\nTable\n" . $body . "\nEndTable";
}

sub manage_example {
    my ($self, $format, $el) = @_;
    my $body = $el->string;
    return $self->inlineblk(start => $format => $el->type) .
      $body . $self->inlineblk(stop => $format => $el->type);
}


=head1 HELPERS

Methods providing some fixed values

=cut



sub inline_table {
    my $self = shift;
    unless (defined $self->{_inline_table}) {
        $self->{_inline_table} = {
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
                                                       html => "\n<span class=\"commentmarker\">END_COMMENT}}:</span></div><!-- stop comment -->\n",  
                                                       ltx => "\n\\end{comment}\n\n",
                                                      },
                                             },
                                  verse => {
                                            start => {
                                                      tex => "\n\n\\startawikiverse\n",
                                                      html => "<pre class=\"verse\">\n",
                                                      ltx => "\n\n\\begin{verse}\n",
                                                     },
                                            stop => {
                                                     tex => "\\stopawikiverse\n\n",
                                                     html => "</pre>\n",
                                                     ltx => "\n\\end{verse}\n\n",
                                                    },
                                           },
                                 };
    }
    return $self->{_inline_table};
}

sub blk_table {
    my $self = shift;
    unless (defined $self->{_blk_table}) {
        $self->{_blk_table} = {
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




1;
