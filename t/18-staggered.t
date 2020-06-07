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

    #  This test is for a staggered layout:
    #
    #  select
    #     foo, bar, baz
    #  from
    #     boobar
    #  ..
    #
    #  but now I'm trying to decide whther I specify an indent on the right
    #  columns, or specify a width for each line .. 

    my $indent = '    ';
    my $indent_size = length ( $indent );

    for my $width (qw/40 50 60 70/) {

        my $block = Text::BlockFormatter->new();

        ok( defined $block, 'Created block object' );

        foreach my $row (@sql) {

            $block->add( { text => [ $row->{left} ] } );
            $block->add_row ( { indent => $indent } );
            $block->add( { text => [ $row->{right} ] } );
            $block->add_row;
        }

        my $output = $block->output;
        ok( defined $output, 'Got some output' );

        my $row = 0;
        foreach my $line ( @{$output} ) {

            cmp_ok( length($line), '<=', $width,
                "Output line is not greater than $width" );

            #  This should alternate between unindented left side and indented
            #  right side, so that's what we're going to test for.

            if ( $line =~ /^(\w+)/ ) {

                like ( $line, qr/$sql[ $row ]->{left}/, 'Unindented left side' );

            } elsif ( $line =~ /^\s{$indent_size}(.+)/ ) {

                like ( $line, qr/$sql[ $row ]->{right}/, 'Indented right side' );
                $row++;

            } else {

                BAIL_OUT ( "Unexpected line $line" );
            }
        }
    }
    done_testing;
}
