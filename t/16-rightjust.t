#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use List::Util qw/max/;

use Text::BlockFormatter;

{
    my @sql = ( {
            left    => 'select',
            'right' => 'OEORDD.CATEGORY, '
              . 'sum((OEORDD.QTYSHPTODT+OEORDD.QTYBACKORD)*OEORDD.UNITPRICE) '
              . 'as TOTAL, rtrim(OEORDH.SALESPER1) as SALESPER1'
        },
        { left => 'from', 'right' => 'OEORDD' },
        {
            left    => 'join',
            'right' => 'OEORDH on OEORDH.ORDUNIQ=OEORDD.ORDUNIQ'
        },
        {
            left => 'where',
            'right' =>
              "OEORDH.ORDNUMBER like '[0-9][0-9][0-9][0-9][0-9][0-9]' and "
              . 'OEORDH.ORDNUMBER >= ? and OEORDH.ORDNUMBER <= ? and '
              . 'OEORDH.CUSTOMER not in '
              . "('PROMO1','PROMO2','REPAIR1','RESERVE1') and "
              . "OEORDH.TERMS not in ('S','SAMPLE') and OEORDH.TYPE = '1'"
        },
        { left => 'group by', 'right' => 'OEORDD.CATEGORY,OEORDH.SALESPER1' },
    );

    #  This is exactly the same code as in 14-somesql.t.

    for my $width (qw/70 74 78/) {

        #  Hmm .. we're creating an object here and setting up a column with
        #  parameters, then lower down calling add .. leaving the first two
        #  untouched. FIXME

        my $block = Text::BlockFormatter->new(
            { cols => [ { wrap => 0, just => 'R' }, { wrap => 1 } ], width => $width } );

        ok( defined $block, 'Created block object' );

        #  We need to track the maximum width of the left column in order to
        #  check the gutter lower down.

        my $max = 0;
        foreach my $row (@sql) {

            $block->add( { col => 0, text => [ $row->{left} ], just => 'R' } );
            $block->add( { col => 1, text => [ $row->{right} ] } );
            $block->add_output_row;

            $max = max( length( $row->{left} ), $max );
        }

        my $output = $block->output;
        ok( defined $output, 'Got some output' );

        my $row = 0;
        foreach my $line ( @{$output} ) {

            cmp_ok( length($line), '<=', $width,
                "Output line is not greater than $width" );

            #  Check that gutter's where we expect it to be ..

            my $gutter = substr( $line, $max, 1 );
            is( $gutter, ' ', 'Gutter is correct' );

            #  Also do a check on lines that aren't continuations to see that
            #  the left column and the first word of the right column are about
            #  what we expect them to be.

            if (   $line !~ /^\s{$max}/
                && $sql[$row]->{right} =~ /(\S+)/ )
            {
                my $expected_word = join( ' ', $sql[$row]->{left}, $1 );
                like( $line, qr/$expected_word/,
                        "Check expected content '$expected_word' was present"
                      . " in row $row" );
                $row++;
            }
        }
    }
    done_testing;
}
