package Text::BlockFormatter;

use 5.006;
use strict;
use warnings;

use constant DEFAULT_WIDTH => 78;

=head1 NAME

Text::BlockFormatter - format text into blocks and columns

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


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
    $block->add(0, \@text);

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

    my $self = {
        width  => $args->{width} // DEFAULT_WIDTH,
        output => [''],
    };

    bless $self, $class;
    return $self
}

sub add
{
    my ( $self, $data ) = @_;

    foreach my $line ( @{$data} ) {

        foreach my $word ( split( /\s/, $line ) ) {

            if ( length( $self->{output}->[-1] ) == 0 ) {

                #  Line's empty .. just add the word.
                #  TODO: For pathological cases, the word could be too long for
                #  the line, in which case we might have to hyphenate.  Yikes.

                $self->{output}->[-1] = $word;

            } elsif (
                length( $self->{output}->[-1] ) + 1 + length($word) <
                $self->{width} )
            {

                #  Line has space for the word .. add the word, with an
                #  intervening space.

                $self->{output}->[-1] .= " $word";

            } else {

                #  There isn't space for the word. Create a new line, and re-do
                #  the loop for this word.

                push( @{ $self->{output} }, '' );
                redo;
            }
        }
    }
}

sub output
{
    my ( $self ) = @_;

    return ( $self->{ output } );
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
