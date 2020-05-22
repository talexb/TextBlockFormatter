package Text::BlockFormatter;

use 5.006;
use strict;
use warnings;

use constant DEFAULT_WIDTH => 78;
use constant DEFAULT_COLUMNS => 1;

=head1 NAME

Text::BlockFormatter - format text into blocks and columns

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module formats text into blocks, which are built from columns, which are
made up of lines.

    my $block = Text::BlockFormatter->new();
    my @text = (
        'Lorem ipsum dolor sit amet,',
        'consectetur adipiscing elit,',
        'sed do eiusmod tempor incididunt',
        'ut labore et dolore magna aliqua.'
    );
    $block->add({text=>\@text});

    my $output = $block->output;

    #  $output contains
    #
    #  Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
    #  tempor incididunt ut labore et dolore magna aliqua.

More examples to come.

=head1 EXPORT

TBA

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new
{
    my ( $class, $args ) = @_;

    #  The block has a default overall width. Within that, there can be one to
    #  many columns. A column can be set not to wrap, such as the case for the
    #  first column of an SQL command (SQL::Tidy, upon which this module
    #  depends). In that case, we have to figure out the maximum width for that
    #  column during the output phase, in order figure to out how much space is
    #  left for the rest of the columns.

    my $self = {
        width   => $args->{width}   // DEFAULT_WIDTH,
    };
    bless $self, $class;

    if ( exists $args->{cols} ) {

        $self->{cols} = $args->{cols};
    }
    $self->_add_output_row;

    return $self
}

#  We need to add another level of indirection so that we have multiple blocks,
#  each of which can have a fixed left block and a variable right block. These
#  blocks need to be checked together, so that the width of the fixed left
#  block can be determined before flowing the variable right block.

sub _add_output_row
{
    my ( $self ) = @_;

    my @output_row;

    if ( exists $self->{cols} ) {

        foreach my $col ( @{ $self->{cols} } ) {

            push(
                @output_row,
                { wrap => $col->{wrap} // 1, output => [''] }
            );
        }

    } else {

        @output_row = ( { wrap => 1, output => [''] } );
    }

    push ( @{ $self->{output} }, \@output_row );
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
    my $space = $self->{width};    #  Initialize space.

    #  We're doing the no wrapping column first, and then the wrapping column,
    #  since the wrapping column needs to know how much space is left.

    foreach my $wrap ( 0 .. 1 ) {

      COL:
        foreach my $col (0 .. ( scalar @{ $self->{output}->[-1] } ) - 1 ) {

            #  Skip this time around the loop if we're not doing this kind of
            #  wrap right now.

            next if ( $self->{output}->[-1]->[$col]->{wrap} != $wrap );

            my @output     = ('');
            my $max_length = 0;

            foreach my $word ( @{ $self->{output}->[-1]->[$col]->{output} } ) {

                if ( length( $output[-1] ) == 0 ) {

                    #  Line's empty .. just add the word.
                    #  TODO: For pathological cases, the word could be too long
                    #  for the line, in which case we might have to hyphenate.
                    #  Yikes.

                    $output[-1] = $word;
                    $max_length = length $output[-1];

                } elsif ( $self->{output}->[-1]->[$col]->{wrap} == 0
                    || length( $output[-1] ) + 1 + length($word) < $space )
                {

                    #  Either we're doing no wrap, or the line has space for
                    #  the word .. we add the word, with an intervening space.

                    $output[-1] .= " $word";
                    $max_length = length $output[-1];

                } else {

                    #  There isn't space for the word. Create a new line, and
                    #  re-do the loop for this word.

                    push( @output, '' );
                    redo;
                }
            }

            #  Either we're doing no wrap -- in which case it's the maximum
            #  length that we saw -- otherwise, it's what was left over.
            #  This means we're only dealing with two columns at a time.

            my $fmt_length =
              $self->{output}->[-1]->[$col]->{wrap} ? $space : $max_length;
            push( @big_output, { fmt => "%-${fmt_length}s", data => \@output } );

            $space -= $max_length;
        }
    }

    #  Now we need to count the number of lines in each of the parts, and
    #  output the greater number of lines. This loop figures out which of the
    #  groups is longest.

    my $max_lines = 0;
    foreach my $col (@big_output) {

        if ( $max_lines < scalar @{$col->{data}} ) { $max_lines = scalar @{$col->{data}}; }
    }

    #  Build the final output, grabbing the relevant line from each group, and
    #  truncating any trailing spaces.

    my @final_output;
    foreach my $line ( 0 .. $max_lines ) {

        my @line;
        foreach my $col ( 0 .. (scalar @{ $self->{output}->[-1] })-1 ) {

            push(
                @line,
                sprintf(
                    $big_output[$col]->{fmt},
                    $big_output[$col]->{data}->[$line] // ''
                )
            );
        }
        push( @final_output, join( ' ', @line ) );
        $final_output[-1] =~ s/\s+$//;    #  Trim trailing spaces.
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
