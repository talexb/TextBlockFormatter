#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use List::Util qw/max/;

use Text::BlockFormatter;

{
    my @sql = ( {
            left    => 'select',
            'right' => 'OEORDD.CATEGORY, '
              . 'sum ( ( OEORDD.QTYSHPTODT + OEORDD.QTYBACKORD ) * OEORDD.UNITPRICE ) '
              . 'as TOTAL, rtrim ( OEORDH.SALESPER1 ) as SALESPER1'
        },
        { left => 'from', 'right' => 'OEORDD' },
        {
            left    => 'join',
            'right' => 'OEORDH on OEORDH.ORDUNIQ = OEORDD.ORDUNIQ'
        },
        {
            left => 'where',
            'right' =>
              "OEORDH.ORDNUMBER like '[0-9][0-9][0-9][0-9][0-9][0-9]' and "
              . 'OEORDH.ORDNUMBER >= ? and OEORDH.ORDNUMBER <= ? and '
              . 'OEORDH.CUSTOMER not in '
              . "( 'PROMO1', 'PROMO2', 'REPAIR1', 'RESERVE1' ) and "
              . "OEORDH.TERMS not in ( 'S', 'SAMPLE' ) and OEORDH.TYPE = '1'"
        },
        { left => 'group by', 'right' => 'OEORDD.CATEGORY, OEORDH.SALESPER1' },
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

        my $block = Text::BlockFormatter->new( { width => $width } );

        ok( defined $block, 'Created block object' );

        foreach my $row (@sql) {

            $block->add( { text => [ $row->{left} ] } );
            $block->add_output_row ( { indent => $indent } );
            $block->add( { text => [ $row->{right} ] } );
            $block->add_output_row;
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

                like ( $line, qr/$sql[ $row ]->{left}/, "Unindented left side / row $row" );
                $row++;

            } else {

                like ( $line, qr/^\s{$indent_size}(.+)/, "Indented right side / row $row" );
            }
        }
    }
    done_testing;
}
