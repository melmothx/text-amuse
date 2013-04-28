use 5.010001;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Element;

plan tests => 248;

sub test_line {
    my $string = shift;
    my $exp = shift;
    print "Testing <$string>\n";
    my $el = Text::Amuse::Element->new($string);
    is($el->type, $exp->{type}, "type ok: $exp->{type}");
    is($el->block, $exp->{block}, "block ok: $exp->{block}");
    is($el->removed, $exp->{removed}, "removed ok");
    if (exists $exp->{indentation}) {
        is($el->indentation, $exp->{indentation}, "indentation ok");
    }
    if (exists $exp->{string}) {
        is($el->string, $exp->{string}, "string ok");
    }

    is($el->rawline, $string, "rawline ok");
}

test_line("* h1", {
                   type => "h1",
                   block => "h1",
                   removed => "* ",
                   indentation => 2
                  });

test_line("** h2", {
                   type => "h2",
                   block => "h2",
                   removed => "** ",
                   indentation => 3
                  });
test_line("*** h3", {
                   type => "h3",
                   block => "h3",
                   removed => "*** ",
                   indentation => 4
                  });
test_line("**** h4", {
                   type => "h4",
                   block => "h4",
                   removed => "**** ",
                   indentation => 5
                  });
test_line("***** h5", {
                   type => "h5",
                   block => "h5",
                   removed => "***** ",
                   indentation => 6
                  });
test_line("", {
               type => "null",
               block => "null",
               removed => "",
               indentation => 0,
              });

test_line("    ", {
               type => "null",
               block => "null",
               removed => "    ",
               indentation => 4,
              });

test_line(" 1. ciao", {
                       type => "li",
                       block => "oln",
                       removed => " 1. ",
                       indentation => 4,
                      });

test_line(" i. ciao", {
                       type => "li",
                       block => "oli",
                       removed => " i. ",
                       indentation => 4,
                      });

test_line(" X. ciao", {
                       type => "li",
                       block => "olI",
                       removed => " X. ",
                       indentation => 4,
                      });

test_line("  B. ciao", {
                       type => "li",
                       block => "olA",
                       removed => "  B. ",
                       indentation => 5,
                      });

test_line("     c. ciao", {
                           type => "li",
                           block => "ola",
                           removed => "     c. ",
                           indentation => 8,
                      });

foreach my $bl (qw/biblio play comment verse
                   center right example quote/) {
    test_line("<$bl> \n", {
                          type => "startblock",
                          block => $bl,
                          removed => "<$bl> \n",
                         });
    test_line("</$bl> \n", {
                          type => "stopblock",
                          block => $bl,
                          removed => "</$bl> \n",
                         });


};

foreach my $bl (qw/biblio play comment verse
                   center right example quote/) {
    test_line(" <$bl>\n", {
                          type => "regular",
                          block => "regular",
                          removed => "",
                         });
    test_line("<a$bl>\n", {
                          type => "regular",
                          block => "regular",
                          removed => "",
                         });

};

test_line(">  a verse", {
                         type => "verse",
                         block => "verse",
                         removed => "> ",
                         indentation => 2,
                       });

test_line("  a quote", {
                        type => 'regular',
                        block => 'quote',
                        removed => "  ",
                        indentation => 2,
                       });
          
test_line("     a quote", {
                        type => 'regular',
                        block => 'quote',
                        removed => "     ",
                        indentation => 5,
                       });

foreach (6, 8, 19) {
    test_line((" " x $_) . "center", {
                        type => 'regular',
                        block => 'center',
                        removed => " " x $_,
                        indentation => $_,
                       });
}

foreach (20, 30) {
    test_line((" " x $_) . "right", {
                        type => 'regular',
                        block => 'right',
                        removed => " " x $_,
                        indentation => $_,
                       });
}

test_line("[1] hello", {
                        type => 'footnote',
                        block => 'footnote',
                        removed => '[1] ',
                        string => "hello"
                       });

test_line("[1450]  hello", {
                        type => 'footnote',
                        block => 'footnote',
                        removed => '[1450]  ',
                        string => "hello"
                       });

test_line("; comment", {
                        type => 'comment',
                        block => 'comment',
                        removed => '; comment',
                        string => "",
                       });

test_line(" table | table", {
                        type => 'table',
                        block => 'table',
                        removed => '',
                        string => " table | table",
                       });


