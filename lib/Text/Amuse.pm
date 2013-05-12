package Text::Amuse;

use 5.010001;
use strict;
use warnings;
use Data::Dumper;
use Text::Amuse::Document;
use Text::Amuse::Output;

=head1 NAME

Text::Amuse - Perl module to generate HTML and LaTeX documents from Emacs Muse markup.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Typical usage which should illustrate all the public methods

    use Text::Amuse;
    my $doc = Text::Amuse->new(file => "test.muse");
    
    # get the title, author, etc.
    my %html_directives = $doc->header_as_html;
    
    # get the table of contents
    my $html_toc = $doc->toc_as_html;
    
    # get the body
    my $html_body = $doc->as_html;
    
    # same for LaTeX
    my %latex_directives = $doc->header_as_latex;
    my $latex_body = $doc->as_latex;
    
    # do we need a \tableofcontents ?
    my $wants_toc = $doc->wants_toc; # (boolean)
    
    # files attached
    my @images = $doc->attachments;
    
    # at this point you can inject the values in a template, which is left
    # to the user. 
    

=head1 CONSTRUCTOR

=head3 new (file => $file)

Create a new Text::Amuse object. You should pass the named parameter
C<file>, pointing to a muse file to process. Please note that you
can't pass a string. Build a wrapper going through a temporary file if
you need to pass strings.

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = \%opts;
    # for now
    $self->{_document_obj} =
      Text::Amuse::Document->new(file => $self->{file},
                                 debug => $self->{debug});
    bless $self, $class;
}

=head3 document

Accessor to the L<Text::Amuse::Document> object. [Internal]

=cut

sub document {
    return shift->{_document_obj};
}


=head2 HTML output

=head3 as_html

Output the HTML document (and cache it in the object)

=cut

sub _html_obj {
    my $self = shift;
    unless (defined $self->{_html_doc}) {
        $self->{_html_doc} =
          Text::Amuse::Output->new(
                                   document => $self->document,
                                   format => 'html',
                                  );
    }
    return $self->{_html_doc};
}


sub as_html {
    my $self = shift;
    unless (defined $self->{_html_output_strings}) {
        $self->{_html_output_strings} = $self->_html_obj->process;
    }
    return unless defined wantarray;
    return join("", @{ $self->{_html_output_strings} });
}

=head3 header_as_html

The directives of the document in HTML (title, authors, etc.),
returned as an hashref.

B<Please note that the keys are not escaped nor manipulated>.

=cut

sub header_as_html {
    my $self = shift;
    $self->as_html; # trigger the html generation. This operation is
                    # not expensive if we already call it, and won't
                    # be the next time.
    unless (defined $self->{_cached_html_header}) {
        $self->{_cached_html_header} = $self->_html_obj->header;
    }
    return $self->{_cached_html_header};
}

=head3 toc_as_html

Return the HTML formatted ToC, as a string.

=cut

sub toc_as_html {
    my $self = shift;
    $self->as_html; # be sure that it's processed
    return $self->_html_obj->html_toc;
}

=head3 raw_html_toc

Return an internal representation of the ToC

=cut 

sub raw_html_toc {
    my $self = shift;
    $self->as_html;
    return $self->_html_obj->table_of_contents;
}



=head2 LaTeX output

=head3 as_latex

Output the (Xe)LaTeX document (and cache it in the object), as a
string.

=cut

sub _latex_obj {
    my $self = shift;
    unless (defined $self->{_ltx_doc}) {
        $self->{_ltx_doc} =
          Text::Amuse::Output->new(
                                   document => $self->document,
                                   format => 'ltx',
                                  );
    }
    return $self->{_ltx_doc};
}

sub as_latex {
    my $self = shift;
    unless (defined $self->{_latex_output_strings}) {
        $self->{_latex_output_strings} = $self->_latex_obj->process;
    }
    return unless defined wantarray;
    return join("", @{ $self->{_latex_output_strings} });
}

=head3 wants_toc

Return true if a toc is needed because we found some headings inside.

=cut

sub wants_toc {
    my $self = shift;
    $self->as_latex;
    my @toc = $self->_latex_obj->table_of_contents;
    return scalar(@toc);
}


=head3 header_as_latex

The LaTeX formatted header, as an hashref.

=cut

sub header_as_latex {
    my $self = shift;
    $self->as_latex;
    unless (defined $self->{_cached_latex_header}) {
        $self->{_cached_latex_header} = $self->_latex_obj->header;
    }
    return $self->{_cached_latex_header};
}

=head2 Helpers

=head3 attachments

Report the attachments (images) found, as a list. This can be invoked
only after a call (direct or indirect) to C<as_html> or C<as_latex>,
or any other operation which scans the body, otherwise you'll get an
empty list.

=cut

sub attachments {
    my $self = shift;
    return $self->document->attachments;
}

=head3 language_code

The language code of the document. This method will looks into the
header of the document, searching for the keys C<lang> or C<language>,
defaulting to C<en>.

=head3 language

Same as above, but returns the human readable version, notably used by
Babel, Polyglossia, etc.

=cut

sub _language_mapping {
    my $self = shift;
    return {
            en => 'english',
            it => 'italian',
            sr => 'serbian',
            hr => 'croatian',
            ru => 'russian',
            es => 'spanish',
            pt => 'portuguese',
            de => 'german',
            fr => 'french',
            nl => 'dutch',
           };
}


sub language_code {
    my $self = shift;
    unless (defined $self->{_doc_language_code}) {
        my %header = $self->document->raw_header;
        my $lang = $header{lang} || $header{language} || "en";
        my $real = "en";
        # check if language exists;
        if ($self->_language_mapping->{$lang}) {
            $real = $lang;
        }
        $self->{_doc_language_code} = $real;
    }
    return $self->{_doc_language_code};
}

sub language {
    my $self = shift;
    unless (defined $self->{_doc_language}) {
        my $lc = $self->language_code;
        # guaranteed not to return undef
        $self->{_doc_language} = $self->_language_mapping->{$lc};
    }
    return $self->{_doc_language};
}

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-amuse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Amuse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Amuse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Amuse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Amuse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Amuse>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Amuse/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

For the people caring about copyright and laws, this is the usual
stuff:

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

1; # End of Text::Amuse
