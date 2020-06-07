#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use List::Util qw/max/;

use Text::BlockFormatter;

{
    my @sql = (
        { left => 'select',   'right' => 'foo, bar, baz' },
        { left => 'from',     'right' => 'boobar' },
        { left => 'where',    'right' => 'quux < 5 and wazoo = "xx"' },
        { left => 'order by', 'right' => 'foo desc, bar' },
    );

    #  Ahh .. and I've just hit another road-block. My assumption has been that
    #  I deal with a single block at a time, when in fact I need to deal with
    #  multiple blocks. And that's going to need some new logic, and probably
    #  an updated interface.

    for my $width (qw/40 50 60 70/) {

        my $block = Text::BlockFormatter->new( {
                cols  => [ { wrap => 0, just => 'R' }, { wrap => 1 } ],
                width => $width
            }
        );

        ok( defined $block, 'Created block object' );

        #  We need to track the maximum width of the left column in order to
        #  check the gutter lower down.

        my $max = 0;
        foreach my $row (@sql) {

            $block->add( { col => 0, text => [ $row->{left} ] } );
            $block->add( { col => 1, text => [ $row->{right} ] } );
            $block->add_row;

            $max = max( length( $row->{left} ), $max );
        }

        my $output = $block->output;
        ok( defined $output, 'Got some output' );

        foreach my $line ( @{$output} ) {

            cmp_ok( length($line), '<=', $width,
                "Output line is not greater than $width" );

            #  Check that gutter's where we expect it to be ..

            my $gutter = substr( $line, $max, 1 );
            is( $gutter, ' ', 'Gutter is correct' );
        }
    }
    done_testing;
}
