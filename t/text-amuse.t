use 5.010001;
use strict;
use warnings;
use Test::More;
use Text::AMuse;
use File::Spec::Functions;
use Data::Dumper;

# plan tests => 1;

diag "Constructor";

my $testfile = catfile(t => 'prova.muse');
my $muse = Text::AMuse->new(file => $testfile, debug => 1);

is($muse->filename, $testfile, "filename ok");
my @expected = (
                "#title 1 2 3 4\n",
                "#author hello\n",
                "\n",
                "This    is a test\n",
                "This    is a test\n",
               );

my @got = $muse->get_lines;
is_deeply(\@got, \@expected, "input ok");


is_deeply [$muse->raw_body],
  ["This    is a test\n", "This    is a test\n", "\n" ],
  "body ok";

is_deeply {$muse->raw_header},
  { title => "1 2 3 4", author => "hello" },
  "header ok";

is(scalar @{$muse->_parsed_body}, 3, "Found three elements");
diag "Testing if I can call rawline, block, type, string, ";
diag "removed, indentation on each element";
foreach my $el (@{$muse->_parsed_body}) {
    ok defined($el->rawline), "el: " . $el->rawline;
    ok defined($el->block),   "el: " . $el->block;
    ok defined($el->type),    "el: " . $el->type;
    ok defined($el->string),  "el: " . $el->string;
    ok defined($el->removed), "el: " . $el->removed;
    ok defined($el->indentation), "el: " . $el->indentation;
}


done_testing();
