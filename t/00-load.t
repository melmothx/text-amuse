#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::AMuse' ) || print "Bail out!\n";
}

diag( "Testing Text::AMuse $Text::AMuse::VERSION, Perl $], $^X" );
