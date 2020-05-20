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

    #  We're aiming for a result like this:
    #
    #  [title] [text text text]
    #          [text text]

    my $output = $block->output;
    ok( defined $output, 'Got some output' );

    foreach my $line ( @{$output} ) {

        cmp_ok( length($line), '<=', 78,
            'Output line is not greater than default width' );
        my $gutter = substr ( $line, length ( $title ), 1 );
        is ( $gutter, ' ', 'Gutter is correct' );
    }
    done_testing;
}
