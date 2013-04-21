package Text::AMuse;

use 5.010001;
use strict;
use warnings;
use Data::Dumper;
use Text::AMuse::Document;

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


=head1 CONSTRUCTOR

=head3 new (file => $file)

Create a new Text::AMuse object

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = \%opts;
    # for now
    $self->{_document_obj} =
      Text::AMuse::Document->new(file => $self->{file},
                                 debug => $self->{debug});
    bless $self, $class;
}

=head3 document

Accessor to the L<Text::AMuse::Document> object

=cut

sub doc {
    return shift->{_document_obj}->document;
}


=head3 as_html

Output the HTML document

=cut

sub as_html {
    my $self = shift;
    unless (defined $self->{_html_doc}) {
        $self->{_html_doc} = $self->process("html");
    }
    return $self->{_html_doc} || "";
}

=head3 as_latex

Output the (Xe)LaTeX document

=cut

sub as_latex {
    my $self = shift;
    unless (defined $self->{_ltx_doc}) {
        $self->{_ltx_doc} = $self->process("ltx");
    }
    return $self->{_ltx_doc} || "";
}


=head3 process ($type)

Return the string for format C<$type>, where $type can be "ltx" or
"html".

=cut


sub process {
    my ($self, $format) = @_;
    my @pieces;
    foreach my $el ($self->doc) {
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
    return "String $format: " . $el->string . "\n";
}

sub manage_header {
    my ($self, $format, $el) = @_;
    return $self->inlineblk(start => $format => $el->type) .
      $self->manage_regular($format, $el) .
        $self->inlineblk(stop => $format => $el->type);
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
    return $body;
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
        $self->{_url_re} = qr!(www\.|https?:\/\/)
                              [\w\-\.]+\.(\w+) # domain
                              (:\d+)* # the port
                              (/\S*?\w)? # everything else, but start
                                         # with a slash and end with a
                                         # a \w, and don't tolerate spaces
                             !x;
    }
    return $self->{_url_re};
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
