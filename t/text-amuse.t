use 5.010001;
use strict;
use warnings;
use Test::More;
use Text::Amuse::Document;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 81;

diag "Constructor";

my $testfile = catfile(t => testfiles =>  'prova.muse');
my $muse = Text::Amuse::Document->new(file => $testfile, debug => 1);

is($muse->filename, $testfile, "filename ok");
my @expected = (
                "#title 1 2 3 4\n",
                "#author hello\n",
                "\n",
                "This    is a test\n",
                "This    is a test\n",
               );

my $got = $muse->get_lines;
is_deeply($got, \@expected, "input ok");


is_deeply [$muse->raw_body],
  ["This    is a test\n", "This    is a test\n", "\n" ],
  "body ok";

is_deeply {$muse->raw_header},
  { title => "1 2 3 4", author => "hello" },
  "header ok";

is(scalar ($muse->parsed_body), 4, "Found three elements");
# diag "Testing if I can call rawline, block, type, string, ";
# diag "removed, indentation on each element";
foreach my $el ($muse->parsed_body) {
    ok defined($el->rawline), "el: " . $el->rawline;
    ok defined($el->block),   "el: " . $el->block;
    ok defined($el->type),    "el: " . $el->type;
    ok defined($el->string),  "el: " . $el->string;
    ok defined($el->removed), "el: " . $el->removed;
    ok defined($el->indentation), "el: " . $el->indentation;
}

my $example =
  Text::Amuse::Document->new(file => catfile(t => testfiles => 'example.muse'));

$example->_catch_example;
my @parsed = $example->parsed_body;

is($parsed[0]->string, "", "First is empty");
is($parsed[1]->type, "example", "Type set to example");
is($parsed[2]->string, "", "Third is empty");
is($parsed[3]->type, "example", "Type set to example");
is($parsed[4]->string, "", "Last is empty");

$example = Text::Amuse::Document->new(file => catfile(t => testfiles => 'example-2.muse'));

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

# dump_content($example);

my $poetry = Text::Amuse::Document->new(file => testfile("verse.muse"),
                              debug => 1);

$poetry->_catch_example;
$poetry->_catch_verse;

@parsed = $poetry->parsed_body;
is($parsed[3]->type, "verse", "verse ok");
is($parsed[3]->string,
   "A line of Emacs verse;\n  forgive its being so terse.\n\n\n",
   "content looks ok");
is($parsed[4]->type, "h2", "h2 ok");
is($parsed[9]->type, "verse", "another verse");
my $exppoetry = <<'EOF';
A line of Emacs verse; [2]
  forgive its being so terse. [3]

In terms of terse verse,
        you could do worse. [1]

 A. This poetry will stop here, even if it's not close

EOF

is($parsed[9]->string, $exppoetry, "content ok, list not interpreted");
is($parsed[10]->type, "footnote", "footnote not eaten");
is($parsed[10]->string, "The author\n", "Footnote ok");
# print $parsed[9]->string;
# dump_content($poetry);

my $packs = Text::Amuse::Document->new(file => catfile(t => testfiles => 'packing.muse'));
$packs->_catch_example;
$packs->_catch_verse;
$packs->_pack_lines;
@parsed = $packs->parsed_body;

is($parsed[1]->string, "this title\nwill merge\n");
is($parsed[1]->type, "h1");

is($parsed[3]->string, "this title\nwill merge\n");
is($parsed[3]->type, "h2");

is($parsed[5]->string, "this title\nwill merge\n");
is($parsed[5]->type, "h3");

is($parsed[7]->string, "this title\nwill merge\n");
is($parsed[7]->type, "h4");

is($parsed[9]->string, "this title\nwill merge\n");
is($parsed[9]->type, "h5");

is($parsed[12]->string, "This will not merge (of course)\n");
is($parsed[12]->type, "regular");

is($parsed[14]->string, "we continue without merging (ugly but valid)\n");
is($parsed[14]->type, "regular");

is($parsed[16]->string, "Verse will not merge (of course)\n");
is($parsed[16]->type, "verse");

is($parsed[17]->string, "and we continue without merging (ugly but valid) [1]\n");
is($parsed[17]->type, "regular");

is($parsed[19]->string, "nor the example\n");
is($parsed[19]->type, "example");

is($parsed[20]->string, "will not merge\n");
is($parsed[20]->type, "regular");

is($parsed[22]->string, "the | table\nwill | merge\n");
is($parsed[22]->type, "table");

is($parsed[25]->string, "the list\nwill merge\n");
is($parsed[25]->type, "li");
is($parsed[25]->block, "ul");

is($parsed[27]->string, "the list\nwill merge\n");
is($parsed[27]->type, "li");
is($parsed[27]->block, "ola");

is($parsed[29]->string, "the footnote\nwill merge\n");
is($parsed[29]->type, "footnote");

is($parsed[31]->string, "");
is($parsed[32]->string, "will not merge\n");


sub dump_content {
    my $obj = shift;
    foreach my $i ($obj->parsed_body) {
        if ($i->type eq 'null') {
            print "** NULL **\n";
            die "null with content?" if $i->string =~ m/\S/;
        } else {
            print "====Start type:", $i->type, "======\n",
              $i->string, "====Stop===\n";
        }
    }
}

sub testfile {
    return catfile(t => testfiles => shift);
}
