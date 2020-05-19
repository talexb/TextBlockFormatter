#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Text::BlockFormatter;

{
    my $block = Text::BlockFormatter->new();
    ok( defined $block, 'Created block object' );

    my @text = (
        'Lorem ipsum dolor sit amet,',
        'consectetur adipiscing elit,',
        'sed do eiusmod tempor incididunt',
        'ut labore et dolore magna aliqua.'
    );
    $block->add( { text => \@text } );

    my $output = $block->output;
    ok( defined $output, 'Got some output' );

    foreach my $line ( @{$output} ) {

        cmp_ok( length($line), '<=', 78,
            'Output line is not greater than default width' );
    }
    done_testing;
}
