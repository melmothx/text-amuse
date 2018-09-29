#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 1;
use Text::Amuse::Functions qw/muse_to_object/;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(UTF-8)";

BEGIN {
    if (!eval q{ use Test::Differences; unified_diff; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

my $muse = <<'MUSE';
#title Test
#lang fr 

stop . semicolon; colon: question? bang! «quote»

stop . semicolon ; colon : question ? bang ! « quote »

http://hello.org

semicolon ; 
colon : 
question ?
bang !
« quote »

<verbatim>bang ! bang !</verbatim>

{{{
bang! and bang !
}}}

MUSE

my $html = <<'HTML';

<p>
stop . semicolon&#160;; colon&#160;: question&#160;? bang&#160;! «&#160;quote&#160;»
</p>

<p>
stop . semicolon&#160;; colon&#160;: question&#160;? bang&#160;! «&#160;quote&#160;»
</p>

<p>
http://hello.org
</p>

<p>
semicolon&#160;;
colon&#160;:
question&#160;?
bang&#160;!
«&#160;quote&#160;»
</p>

<p>
bang ! bang !
</p>

<pre class="example">
bang! and bang !
</pre>
HTML

my $latex = <<'LATEX';

LATEX

{
    my $obj = muse_to_object($muse);
    eq_or_diff $obj->as_html, $html;
}

