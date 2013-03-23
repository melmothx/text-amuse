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

is(scalar ($muse->parsed_body), 4, "Found three elements");
diag "Testing if I can call rawline, block, type, string, ";
diag "removed, indentation on each element";
foreach my $el ($muse->parsed_body) {
    ok defined($el->rawline), "el: " . $el->rawline;
    ok defined($el->block),   "el: " . $el->block;
    ok defined($el->type),    "el: " . $el->type;
    ok defined($el->string),  "el: " . $el->string;
    ok defined($el->removed), "el: " . $el->removed;
    ok defined($el->indentation), "el: " . $el->indentation;
}

my $lists = Text::AMuse->new(file => catfile(t => 'lists.muse'));

# print Dumper([$lists->parsed_body]);

my $example = Text::AMuse->new(file => catfile(t => 'example.muse'));

$example->_catch_example;
my @parsed = $example->parsed_body;

is($parsed[0]->string, "", "First is empty");
is($parsed[1]->type, "example", "Type set to example");
is($parsed[2]->string, "", "Third is empty");
is($parsed[3]->type, "example", "Type set to example");
is($parsed[4]->string, "", "Last is empty");

$example = Text::AMuse->new(file => catfile(t => 'example-2.muse'));

$example->_catch_example;
@parsed = $example->parsed_body;
is(scalar @parsed, 4, "Four element, <example> wasn't closed");
is($parsed[0]->string, "", "First is empty");
is($parsed[1]->type, "example", "Type set to example");
is($parsed[2]->string, "", "Third is empty");
is($parsed[3]->type, "example", "Type set to example");

# we have to add a "\n" at the end, because it's inserted automatically
my $expected_example = <<'EOF';

      1, 2, 3

           Test [2]

[2] Not a footnote



EOF

is($parsed[3]->string, $expected_example, "Content looks ok");

dump_content($example);

done_testing();


sub dump_content {
    my $obj = shift;
    foreach my $i ($obj->parsed_body) {
        print ">> Start type: ", $i->type, "\n",
          $i->string, ">> Stop\n";
    }
}
