use 5.010001;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Document;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 1;

my $list = Text::Amuse::Document->new(file => catfile(t => testfiles => 'lists.muse'));

my @good;

my @expected = (
                {
                 'string' => 'Normal text.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'ul',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 1, bullet item one, this is the first paragraph. I can break
the line, keeping the same amount of indentation
',
                 'block' => 'ul',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'oln',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item one. i can break the line, keeping the same
amount of indentation
',
                 'block' => 'oln',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item two
which continues
',
                 'block' => 'oln',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'oln',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 1, bullet item two
which continues
',
                 'block' => 'ul',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'oln',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item one
which continues
',
                 'block' => 'oln',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item two
which continues
',
                 'block' => 'oln',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'oli',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 3, enum item i
',
                 'block' => 'oli',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues
the item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 3, enum item ii
',
                 'block' => 'oli',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues
the item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'oli',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item three
which continues
',
                 'block' => 'oln',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'oln',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Back to Level 1, third bullet
',
                 'block' => 'ul',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'ola',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => "Level 2, enum item \x{201c}a\x{201d}
which continues
",
                 'block' => 'ola',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => "Level 2, enum item \x{201c}b\x{201d}
which continues
",
                 'block' => 'ola',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'olI',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => "Level 3, enum item \x{201c}I\x{201d}
",
                 'block' => 'olI',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'olI',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'ola',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Back to the bullets
',
                 'block' => 'ul',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'ul',
                 'type' => 'stopblock'
                }
               );

foreach my $e ($list->document) {
    next if $e->type eq 'null';
    push @good, {
                 type  => $e->type,
                 block => $e->block,
                 string => $e->string,
                };
}

is_deeply(\@good, \@expected);



dump_doc($list);

sub dump_doc {
    my $obj = shift;
    print q{
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
      xml:lang="en" lang="en">
  <head>
<title>test</title>
</head>
<body>
};
    foreach my $el ($obj->document) {
        my $block = $el->block;
        if ($block =~ m/(ol)/) {
            $block = $1;
        }
        if ($el->type eq 'startblock') {
            print '<' . $block . '>' . "\n";
        }
        elsif ($el->type eq 'stopblock')  {
            print '</' . $block . '>' . "\n";
        }
        elsif ($el->type ne 'null') {
            print '<p>', $el->string, '</p>';
        }
    }
    print "</body></html>\n";
}
