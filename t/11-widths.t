#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Text::BlockFormatter;

{
    my @text = (
        'Lorem ipsum dolor sit amet,',
        'consectetur adipiscing elit,',
        'sed do eiusmod tempor incididunt',
        'ut labore et dolore magna aliqua.'
    );

    for my $width (qw/20 30 40 50 60 70/) {

        my $block = Text::BlockFormatter->new( { width => $width } );
        ok( defined $block, 'Created block object' );

        $block->add( { text => \@text } );

        my $output = $block->output;
        ok( defined $output, 'Got some output' );

        foreach my $line ( @{$output} ) {

            cmp_ok( length($line), '<=', $width,
                "Output line is not greater than $width" );
        }
    }
    done_testing;
}
