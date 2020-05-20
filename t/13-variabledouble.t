#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Text::BlockFormatter;

{
    my $title = 'Some Latin text';
    my @text  = (
        'Lorem ipsum dolor sit amet,',
        'consectetur adipiscing elit,',
        'sed do eiusmod tempor incididunt',
        'ut labore et dolore magna aliqua.'
    );

    for my $width (qw/30 40 50 60 70/) {

        my $block = Text::BlockFormatter->new(
            { cols => [ { wrap => 0 }, { wrap => 1 } ], width => $width } );
        ok( defined $block, 'Created block object' );

        $block->add( { col => 0, text => [$title] } );
        $block->add( { col => 1, text => \@text } );

        my $output = $block->output;
        ok( defined $output, 'Got some output' );

        foreach my $line ( @{$output} ) {

            cmp_ok( length($line), '<=', $width,
                "Output line is not greater than $width" );
            my $gutter = substr( $line, length($title), 1 );
            is( $gutter, ' ', 'Gutter is correct' );
        }
    }
    done_testing;
}
