package Text::BlockFormatter;

use 5.006;
use strict;
use warnings;

use constant DEFAULT_WIDTH => 78;
use constant DEFAULT_COLUMNS => 1;

use List::Util qw/max/;

=head1 NAME

Text::BlockFormatter - format text into blocks and columns

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

The impetus for this module is a desire to format SQL tidily.  This module
formats text (words and punctuation, separated by spaces) into blocks,
performing word wrapping when the input text overflows the block width.

    my $block = Text::BlockFormatter->new();
    my @text = (
        'Lorem ipsum dolor sit amet,',
        'consectetur adipiscing elit,',
        'sed do eiusmod tempor incididunt',
        'ut labore et dolore magna aliqua.'
    );
    $block->add({text=>\@text});

    my $output = $block->output;

This produces:

    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua.

The block width defaults to 78, but can be set to any size.

    my $block = Text::BlockFormatter->new( { width => $width } );

A block normally contains a single column, but we can also specify two columns.
In this example, the first column is set to not wrap.

    my $block = Text::BlockFormatter->new(
      { cols => [ { wrap => 0 }, { wrap => 1 } ] } );

    my $title = 'Some Latin text';
    $block->add( { col => 0, text => [ $title ]  } );
    my @text = (
        'Lorem ipsum dolor sit amet,',
        'consectetur adipiscing elit,',
        'sed do eiusmod tempor incididunt',
        'ut labore et dolore magna aliqua.'
    );
    $block->add( { col => 1, text => \@text } );

    my $output = $block->output;

This produces:

    Some Latin text Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed
                    do eiusmod tempor incididunt ut labore et dolore magna aliqua.

We can also set a block's justification to be right, instead of the default
left setting.  This allows us to format the SQL statement

    select foo, bar, baz from boobar
    where quux < 5 and wazoo = "xx"
    order by foo desc, bar

using

    my $block = Text::BlockFormatter->new(
        { cols => [ { wrap => 0 }, { wrap => 1 } ], width => $width } );

and specifying the following blocks and columns:

    block   col 0       col 1
      0     select      foo, bar
      1     from        boobar
      2     where       quux < 5 and wazoo = "xx"
      3     order by    foo desc, bar

to get the output:

      select foo, bar, baz
        from boobar
       where quux < 5 and wazoo = "xx"
    order by foo desc, bar

This gives us a gutter with the keywords on the left (and right-justified) and
with the rest of the lines on the right (and left-justified). The gutter is
currently fixed at a single space.

The staggered format is also possible using this module, by specifying the
indent string to be used with a block. First, a regular, non-indented block is
specified for text from the first column:

    my $block = Text::BlockFormatter->new();
    $block->add( { text => [ $row->{left} ] } );

Then we add an output row with an indent, and add the text from the second
column:

    $block->add_output_row ( { indent => $indent } );
    $block->add( { text => [ $row->{right} ] } );

This produces the output:

    select
        foo, bar, baz
    from
        boobar
    where
        quux < 5 and wazoo = "xx"
    order by
        foo desc, bar

These examples are taken from the test suite.

=head1 EXPORT

TBA

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a block object.

=head2 C<add_output_row>

Add an output row.

=head2 C<add>

Add text to the block object.

=head2 C<output>

Output all of the text.

=cut

sub new
{
    my ( $class, $args ) = @_;

    #  The block has a default overall width. Within that, there can be one to
    #  many rows, each of which contains columns. A column can be set not to
    #  wrap, such as the case for the first column of an SQL command
    #  (SQL::Tidy, upon which this module depends). In that case, we have to
    #  figure out the maximum width for each of the row's non-wrapping columns
    #  during the output phase, in order figure to out how much space is left
    #  for the rest of the columns.

    my $self = {
        width   => $args->{width}   // DEFAULT_WIDTH,
    };
    bless $self, $class;

    if ( exists $args->{cols} ) {

        $self->{cols} = $args->{cols};
    }

    #  This method creates the first output row, and more will be added as
    #  necessary.

    $self->add_output_row;

    return $self
}

#  We need to add another level of indirection so that we have multiple blocks,
#  each of which can have a fixed left block and a variable right block. These
#  blocks need to be checked together, so that the width of the fixed left
#  block can be determined before flowing the variable right block.

#  In addition, justification defaults to L, but R justification is possible.
#  The code will look for an R to do right justification, and any other value
#  will fall back to left justification. It's possible to do centre
#  justification, but I don't see that as useful right now.

sub add_output_row
{
    my ($self, $args) = @_;

    my @output_row;

    if ( exists $self->{cols} ) {

        foreach my $col ( @{ $self->{cols} } ) {

            push(
                @output_row,
                {
                    wrap   => $col->{wrap} // 1,
                    just   => $col->{just} // 'L',
                    indent => '',
                    output => []
                }
            );
        }

    } else {

        @output_row = ( {
                wrap   => 1,
                just   => 'L',
                indent => $args->{indent} // '',
                output => []
            }
        );
    }

    push( @{ $self->{output} }, \@output_row );
}

sub add
{
    my ( $self, $data ) = @_;

    #  Default to the first column if none is specified.

    my $col = exists $data->{col} ? $data->{col} : 0;

    #  Stuff every word of every line into the selected column, and worry about
    #  wrapping the text during the output stage.

    foreach my $line ( @{$data->{text}} ) {

        foreach my $word ( split( /\s/, $line ) ) {

            push ( @{ $self->{output}->[-1]->[$col]->{output} }, $word );
        }
    }
}

sub output
{
    my ($self) = @_;

    #  For now, we're taking the shortcut of ignoring the wrap option, and just
    #  capturing a single block's output. We're also usiing the block's width
    #  in figuring out when to do a new line; for multiple columns, this will
    #  have to be a multi-pass process in order to find out the maximum width
    #  for the no wrap columns and then figure out how much space is left for
    #  the remaining columns.

    #  Build a list of lists of lines, capturing the maximum width of each
    #  column. We start with the columns that have wrap disabled, then continue
    #  with the rest of the columns, using the remaining available space. The
    #  trivial case is where the first column is no wrap (for SQL::Tidy), and
    #  the second column is normal. Currently this code doesn't handle more
    #  than two columns.

    my @big_output;
    my $block_space = $self->{width};    #  Initialize space.

    #  We may have an empty row at the end .. let's delete that so as to avoid
    #  problems later on.

    my $empty_row = 1;
    foreach my $row ( @{ $self->{output}->[-1] } ) {

        if ( scalar @{ $row->{output} } ) { $empty_row = 0; last; }
    }

    if ( $empty_row ) { pop @{ $self->{output} }; }

    #  We're doing the no wrapping column first (the left column), and then the
    #  wrapping column (the right column), since the wrapping column needs to
    #  know how much space is left after we've found the largest non-wrapping
    #  column.

    my $max_length = 0;
    foreach my $wrap ( 0 .. 1 ) {

        #  We're looking at each block (think of blocks stacked vertically).

        foreach my $block ( 0 .. ( scalar @{ $self->{output} } ) - 1 ) {

          COL:
            foreach
              my $col ( 0 .. ( scalar @{ $self->{output}->[$block] } ) - 1 )
            {

                #  Skip this time around the loop if we're not doing this kind of
                #  wrap right now.

                next if ( $self->{output}->[$block]->[$col]->{wrap} != $wrap );

                my @output = ('');
                my $space  = $block_space -
                  length( $self->{output}->[$block]->[$col]->{indent} );

                foreach
                  my $word ( @{ $self->{output}->[$block]->[$col]->{output} } )
                {

                    if ( length( $output[-1] ) == 0 ) {

                        #  Line's empty .. just add the word.
                        #  TODO: For pathological cases, the word could be too
                        #  long for the line, in which case we might have to
                        #  hyphenate.  Yikes.

                        $output[-1] =
                          $self->{output}->[$block]->[$col]->{indent} . $word;
                        $max_length = max ( $max_length, length $output[-1] );

                    } elsif ( $self->{output}->[$block]->[$col]->{wrap} == 0
                        || length( $output[-1] ) + 1 + length($word) < $space )
                    {

                        #  Either we're doing no wrap, or the line has space
                        #  for the word .. we add the word, with an intervening
                        #  space.

                        $output[-1] .= " $word";
                        $max_length = max ( $max_length, length $output[-1] );

                    } else {

                        #  There isn't space for the word. Create a new line,
                        #  and re-do the loop for this word.

                        push( @output, '' );
                        redo;
                    }
                }

                #  This code is skipped the first time through (for non-wrap
                #  columns) since we don't yet know what the maximum width is.
                #  The second time through, we're doing the wrapped columns,
                #  and we know how much space there is left.

                if ( $wrap == 1 ) {

                    #  Implement right justification here.

                    my $fmt =
                      $self->{output}->[$block]->[$col]->{just} eq 'R'
                      ? "%${space}s"
                      : "%-${space}s";

                    $big_output[ $block ][ $col ] =
                        { fmt => $fmt, data => \@output };
                }
            }
        }

        #  After the non-wrap section, we know what the maximum width is, and
        #  we can now add the text to the big output array. This duplicates the
        #  some of the logic from the loop above.

        if ( $wrap == 0 ) {

            $block_space -= $max_length;

            foreach my $block ( 0 .. ( scalar @{ $self->{output} } ) - 1 ) {

                foreach
                  my $col ( 0 .. ( scalar @{ $self->{output}->[$block] } ) - 1 )
                {
                    next
                      if ( $self->{output}->[$block]->[$col]->{wrap} != $wrap );

                    #  This just short-circuits the if statement above by
                    #  putting all of the words in this section into a string.
                    #  We then use the maximum length, figured out by going
                    #  through all of the layers of non-wrapped columns, to
                    #  format that string.

                    my $text = join( ' ',
                        @{ $self->{output}->[$block]->[$col]->{output} } );

                    my $fmt =
                      $self->{output}->[$block]->[$col]->{just} eq 'R'
                      ? "%${max_length}s"
                      : "%-${max_length}s";

                    $big_output[$block][$col] =
                      { fmt => $fmt, data => [$text] };
                }
            }
        }
    }

    #  Now we need to count the number of lines in each of the parts, and
    #  output the greater number of lines. This loop figures out which of the
    #  groups is longest.

    my @block_max;
    foreach my $block (0 .. (scalar @big_output)-1 ) {

        $block_max[ $block ] = 0;
        foreach my $col ( 0 .. ( scalar @{ $big_output[$block] } ) - 1 ) {

            $block_max[$block] =
              max( $block_max[$block],
                scalar @{ $big_output[$block][$col]->{data} } );
        }
    }

    #  Build the final output, grabbing the relevant line from each block, line
    #  and column, and truncating any trailing spaces.

    my @final_output;
    foreach my $block ( 0 .. ( scalar @big_output ) - 1 ) {

        foreach my $line ( 0 .. $block_max[$block] - 1 ) {

            my @line;
            foreach my $col ( 0 .. ( scalar @{ $big_output[$block] } ) - 1 ) {

                push(
                    @line,
                    sprintf(
                        $big_output[$block][$col]->{fmt},
                        $big_output[$block][$col]->{data}->[$line] // ''
                    )
                );
            }
            push( @final_output, join( ' ', @line ) );
            $final_output[-1] =~ s/\s+$//;    #  Trim trailing spaces.
        }
    }

    #  Clean up empty line at the end.

    if ( $final_output[-1] eq '' ) { pop @final_output; }

    return ( \@final_output );
}

=head1 AUTHOR

Alex Beamish, C<< <talexb at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-blockformatter at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-BlockFormatter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::BlockFormatter


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-BlockFormatter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-BlockFormatter>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Text-BlockFormatter>

=item * Search CPAN

L<https://metacpan.org/release/Text-BlockFormatter>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Alex Beamish.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Text::BlockFormatter
