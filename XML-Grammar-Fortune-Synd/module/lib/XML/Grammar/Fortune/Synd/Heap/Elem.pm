package XML::Grammar::Fortune::Synd::Heap::Elem;

use strict;
use warnings;

=head1 NAME

XML::Grammar::Fortune::Synd::Heap::Elem - heap element class for
XML::Grammar::Fortune::Synd. For internal use.

=cut

use parent 'Class::Accessor';

__PACKAGE__->mk_accessors(
    qw(
        date
        id
        idx
        file
        )
);

# "All problems in computer science can be solved by
# adding another level of indirection;"
# -- http://en.wikipedia.org/wiki/Abstraction_layer
sub cmp
{
    my ( $self, $other ) = @_;
    return (   ( $self->date()->compare( $other->date() ) )
            || ( $self->idx() <=> $other->idx() ) );
}

1;

=head1 SYNOPSIS

For internal use.

=head1 FUNCTIONS

=head2 cmp()

Internal use.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/Expat License

L<http://www.opensource.org/licenses/mit-license.php>

=cut

