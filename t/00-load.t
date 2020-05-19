#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::BlockFormatter' ) || print "Bail out!\n";
}

diag( "Testing Text::BlockFormatter $Text::BlockFormatter::VERSION, Perl $], $^X" );
