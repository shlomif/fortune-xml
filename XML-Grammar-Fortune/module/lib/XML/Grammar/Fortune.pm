package XML::Grammar::Fortune;

use warnings;
use strict;

use Fatal (qw(open));

use XML::LibXML;
use XML::LibXSLT;

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(
    _mode
    _input
    _output
    ));

=head1 NAME

XML::Grammar::Fortune - convert the FortunesXML grammar to other formats and from plaintext.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

TODO : Fill in.

=head1 FUNCTIONS

=head2 my $processor = XML::Grammar::Fortune->new({mode => $mode, input => $in, output => $out});

Creates a new processor with mode $mode, and input and output files.

=cut

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->_mode($args->{mode});

    $self->_input($args->{input});
    $self->_output($args->{output});

    return 0;
}

=head2 $self->run()

Runs the processor. If $mode is "validate", validates the document.

=cut

sub run
{
    my $self = shift;

    my $mode = $self->_mode();

    if ($mode eq "validate")
    {
        my $rngschema = XML::LibXML::RelaxNG->new(
            location => "./extradata/fortune-xml.rng" 
        );

        my $doc = XML::LibXML->new->parse_file($self->_input());

        my $code;
        $code = $rngschema->validate($doc);

        if ($code)
        {
            die "Invalid file!";
        }

        return $code;
    }
    elsif ($mode eq "convert_to_html")
    {
        my $parser = XML::LibXML->new();
        my $xslt = XML::LibXSLT->new();

        my $style_doc = $parser->parse_file("./extradata/fortune-xml-to-html.xslt");
        my $stylesheet = $xslt->parse_stylesheet($style_doc);

        my $source = XML::LibXML->new->parse_file($self->_input());

        my $results = $stylesheet->transform($source);

        open my $xhtml_out_fh, ">", $self->_output();
        binmode ($xhtml_out_fh, ":utf8");
        print {$xhtml_out_fh} $stylesheet->output_string($results);
        close($xhtml_out_fh);
    }
}
=head1 FUNCTIONS

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at iglu.org.il> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-grammar-fortune at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fortune>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Grammar::Fortune


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fortune>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Grammar-Fortune>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Grammar-Fortune>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Grammar-Fortune>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1; # End of XML::Grammar::Fortune
