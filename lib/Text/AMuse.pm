package Text::AMuse;

use 5.010001;
use strict;
use warnings;
use Data::Dumper;
use Text::AMuse::Document;
use Text::AMuse::Output;

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

sub document {
    return shift->{_document_obj};
}


=head3 output

Accesso to the L<Text::AMuse::Output> object

=cut

sub output {
    my $self = shift;
    unless (defined $self->{_output_obj}) {
        $self->{_output_obj} =
          Text::AMuse::Output->new(
                                   document => $self->document
                                  );
    }
    return $self->{_output_obj};
}


=head3 as_html

Output the HTML document (and cache it in the object)

=cut

sub as_html {
    my $self = shift;
    unless (defined $self->{_html_doc}) {
        $self->{_html_doc} = $self->output->process("html");
    }
    return $self->{_html_doc} || "";
}

=head3 as_latex

Output the (Xe)LaTeX document (and cache it in the object)

=cut

sub as_latex {
    my $self = shift;
    unless (defined $self->{_ltx_doc}) {
        $self->{_ltx_doc} = $self->output->process("ltx");
    }
    return $self->{_ltx_doc} || "";
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
