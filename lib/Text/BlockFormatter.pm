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

    if ( exists $args->{cols} ) {

    } else {

        $self->{output} = [ { wrap => 1, output => [''] } ];
    }

    bless $self, $class;
    return $self
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

            push ( @{ $self->{output}->[$col]->{output} }, $word );
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

    my @output = ('');
    foreach my $col ( scalar @{ $self->{output} } ) {

        foreach my $word ( @{ $self->{output}->[$col]->{output} } ) {

            if ( length( $output[-1] ) == 0 ) {

                #  Line's empty .. just add the word.
                #  TODO: For pathological cases, the word could be too long for
                #  the line, in which case we might have to hyphenate.  Yikes.

                $output[-1] = $word;

            } elsif (
                length( $output[-1] ) + 1 + length($word) < $self->{width} )
            {

                #  Line has space for the word .. add the word, with an
                #  intervening space.

                $output[-1] .= " $word";

            } else {

                #  There isn't space for the word. Create a new line, and re-do
                #  the loop for this word.

                push( @output, '' );
                redo;
            }
        }
    }
    return ( \@output );
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
