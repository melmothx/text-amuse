package Text::Amuse::InlineElement;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Amuse::InlineElement - Helper for Text::Amuse

=head1 METHODS/ACCESSORS

Everything here is pretty much internal only, underdocumented and
subject to change.

=head3 new(%args)

Constructor

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {
                type => '',
                string => '',
                last_position => 0,
                tag => '',
                tag_name => '',
                fmt => '',
               };
    foreach my $k (keys %$self) {
        if (defined $args{$k}) {
            $self->{$k} = $args{$k};
        }
    }
    die "Missing type for <$self->{string}>" unless $self->{type};
    unless ($self->{fmt} eq 'ltx' or $self->{fmt} eq 'html') {
        die "Missing format $self->{fmt} for <$self->{string}>"
    }
    bless $self, $class;
}

sub type {
    my ($self, $type) = @_;
    if ($type) {
        $self->{type} = $type;
    }
    return $self->{type};
}

sub last_position {
    shift->{last_position};
}

sub string {
    shift->{string};
}

sub append {
    my ($self, $element) = @_;
    $self->{string} .= $element->string;
    $self->{last_position} = $element->last_position;
}

sub tag {
    shift->{tag};
}

sub tag_name {
    shift->{tag_name};
}

sub fmt {
    shift->{fmt};
}

sub stringify {
    my $self = shift;
    if ($self->type eq 'text') {
        if ($self->is_latex) {
            my $string = $self->escape_tex($self->string);
            $string = $self->_ltx_replace_ldots($string);
            $string = $self->_ltx_replace_slash($string);
            return $string;
        }
        elsif ($self->is_html) {
            return $self->escape_all_html($self->string);
        }
        else {
            die "Not reached";
        }
    }
    if ($self->type eq 'verbatim') {
        if ($self->is_latex) {
            return $self->escape_tex($self->string);
        }
        elsif ($self->is_html) {
            return $self->escape_all_html($self->string);
        }
        else {
            die "Not reached";
        }
    }
    elsif ($self->type eq 'anchor') {
        my $anchor = $self->string;
        $anchor =~ s/[^A-Za-z0-9]//g;
        die "Bad anchor " . $self->string unless length($anchor);
        if ($self->is_latex) {
            return "\\hyperdef{amuse}{$anchor}{}\%\n";
        }
        elsif ($self->is_html) {
            return qq{<a id="text-amuse-label-$anchor" class="text-amuse-internal-anchor"><\/a>}
        }
        else {
            die "Not reached";
        }
    }
    elsif ($self->type eq 'open' or $self->type eq 'close') {
        my $out = $self->markup_table->{$self->tag}->{$self->type}->{$self->fmt};
        die "Missing markup for $self->fmt $self->type $self->tag" unless $out;
        return $out;
    }
    elsif ($self->type eq 'br') {
        if ($self->is_latex) {
            return '\\forcelinebreak ';
        }
        else {
            return '<br />';
        }
    }
    else {
        die "Unrecognized type " . $self->type . " for " . $self->string;
    }
}

sub markup_table {
    return {
            'em' => {
                     open => {
                              html => '<em>',
                              ltx => "\\emph{"
                             },
                     close => {
                               html => '</em>',
                               ltx => '}',
                              }
                    },
            'strong' => {
                         open => {
                                  html => '<strong>',
                                  ltx => "\\textbf{"
                                 },
                         close => {
                                   html => '</strong>',
                                   ltx => '}',
                                  }
                        },
            'code' => {
                       open => {
                                html => '<code>',
                                ltx => "\\texttt{",
                             },
                     close => {
                               html => '</code>',
                               ltx => '}',
                              }
                    },
            'strike' => {
                         open => {
                                  html => '<strike>',
                                  ltx => "\\sout{"
                                 },
                         close => {
                                   html => '</strike>',
                                   ltx => '}',
                                  }
                        },
            'del' => {
                      open => {
                               html => '<del>',
                               ltx => "\\sout{"
                             },
                     close => {
                               html => '</del>',
                               ltx => '}',
                              }
                    },
            'sup' => {
                     open => {
                              html => '<sup>',
                              ltx => "\\textsuperscript{"
                             },
                     close => {
                               html => '</sup>',
                               ltx => '}',
                              }
                    },
            'sub' => {
                      open => {
                               html => '<sub>',
                               ltx => "\\textsubscript{"
                             },
                     close => {
                               html => '</sub>',
                               ltx => '}',
                              }
                    },
           };
}

sub _ltx_replace_ldots {
    my ($self, $string) = @_;
    my $ldots = "\\dots{}";
    $string =~ s/\.{3,4}/$ldots/g ;
    $string =~ s/\x{2026}/$ldots/g;
    return $string;
}

sub _ltx_replace_slash {
    my ($self, $string) = @_;
    $string =~ s!/!\\Slash{}!g;
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

sub escape_tex {
    my ($self, $string) = @_;
    $string =~ s/\\/\\textbackslash{}/g;
    $string =~ s/#/\\#/g ;
    $string =~ s/\$/\\\$/g;
    $string =~ s/%/\\%/g;
    $string =~ s/&/\\&/g;
    $string =~ s/_/\\_/g ;
    $string =~ s/\{/\\{/g ;
    $string =~ s/\}/\\}/g ;
    $string =~ s/\\textbackslash\\\{\\\}/\\textbackslash{}/g;
    $string =~ s/~/\\textasciitilde{}/g ;
    $string =~ s/\^/\\^{}/g ;
    $string =~ s/\|/\\textbar{}/g;
    return $string;
}


sub is_latex {
    shift->fmt eq 'ltx';
}

sub is_html {
    shift->fmt eq 'html';
}

sub unroll {
    my $self = shift;
    my @new;
    my %map = (
               '=' => [qw/code/],
               '*' => [qw/em/],
               '**' => [qw/strong/],
               '***' => [qw/strong em/],
              );
    if ($self->type eq 'open_inline') {
        push @new, map { +{ type => 'open', tag => $_ } } @{$map{$self->tag}};
    }
    elsif ($self->type eq 'close_inline') {
        push @new, map { +{ type => 'close', tag => $_ } } reverse @{$map{$self->tag}};
    }
    else {
        die "unroll can be called only on close_inline/open_inline, not " . $self->type . " " . $self->string;
    }
    return map { __PACKAGE__->new(%$_, string => '', fmt => $self->fmt) } @new;
}


1;
