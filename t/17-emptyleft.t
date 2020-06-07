#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Text::BlockFormatter;

{
    my $block = Text::BlockFormatter->new( { cols => [ { wrap => 0 }, { wrap => 1 } ] } );
    ok( defined $block, 'Created two column block object' );

    my $title = 'Some Latin text';
    $block->add( { col => 0, text => [ $title ]  } );
    my @text = (
        'Lorem ipsum dolor sit amet,',
        'consectetur adipiscing elit,',
        'sed do eiusmod tempor incididunt',
        'ut labore et dolore magna aliqua.'
    );
    $block->add( { col => 1, text => \@text } );
    $block->add_row;

    $block->add( { col => 1, text => \@text } );

    #  We're aiming for a result like this:
    #
    #  [title] [text text text]
    #          [text text]
    #          [text text text]
    #          [text text]
    #
    #  so as to test the layout possibility of having text in just the right
    #  side of the block.

    my $output = $block->output;
    ok( defined $output, 'Got some output' );

    my $len = length ( $title );
    my $count = 0;

    foreach my $line ( @{$output} ) {

        cmp_ok( length($line), '<=', 78,
            'Output line is not greater than default width' );
        my $gutter = substr ( $line, $len, 1 );
        is ( $gutter, ' ', 'Gutter is correct' );

        if ( $count++ ) {

            like ( $line, qr/^\s{$len}/, "Saw $len leading spaces" );
        }
    }
    done_testing;
}
