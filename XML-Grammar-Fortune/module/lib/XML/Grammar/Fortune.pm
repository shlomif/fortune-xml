package XML::Grammar::Fortune;

use warnings;
use strict;

use Fatal (qw(open));

use File::Spec;

use XML::LibXML;
use XML::LibXSLT;

use File::ShareDir ':ALL';

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(
    _data_dir
    _mode
    _output_mode
    _rng_schema
    _xslt_stylesheet
    _xslt_obj
    _xml_parser
    ));

=head1 NAME

XML::Grammar::Fortune - convert the FortunesXML grammar to other formats and from plaintext.

=head1 VERSION

Version 0.0500

=cut

our $VERSION = '0.0500';


=head1 SYNOPSIS

    use XML::Grammar::Fortune;

    # Validate files.

    my $validator = 
        XML::Grammar::Fortune->new(
            {
                mode => "validate"
            }
        );

    # Returns 0 upon success - dies otherwise
    exit($validator->run({input => "my-fortune-file.xml"}));

    # Convert files to XHTML.
    
    my $converter =
        XML::Grammar::Fortune->new(
            {
                mode => "convert_to_html",
                output_mode => "filename"
            }
        )
    
    $converter->run(
        {
            input => "my-fortune-file.xml",
            output => "resultant-file.xhtml",
        }
    )

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

sub _calc_rng_schema
{
    my $self = shift;

    return
        XML::LibXML::RelaxNG->new(
            location =>
            File::Spec->catfile(
                $self->_data_dir(), 
                "fortune-xml.rng",
            ),
        );
}

sub _get_rng_schema
{
    my $self = shift;

    if (!defined($self->_rng_schema()))
    {
        $self->_rng_schema($self->_calc_rng_schema);
    }

    return $self->_rng_schema();
}

sub _calc_xslt_stylesheet
{
    my $self = shift;

    return 
        $self->_get_xslt_obj->parse_stylesheet(
            $self->_get_xml_parser()->parse_file(
                File::Spec->catfile(
                    $self->_data_dir(),
                    "fortune-xml-to-html.xslt",
                )
            )
        );
}

sub _get_xslt_stylesheet
{
    my $self = shift;

    if (! $self->_xslt_stylesheet())
    {
        $self->_xslt_stylesheet($self->_calc_xslt_stylesheet());
    }

    return $self->_xslt_stylesheet();
}

sub _get_xml_parser
{
    my $self = shift;

    if (! $self->_xml_parser())
    {
        $self->_xml_parser(
            XML::LibXML->new()
        );
    }

    return $self->_xml_parser();
}

sub _get_xslt_obj
{
    my $self = shift;

    if (! $self->_xslt_obj())
    {
        $self->_xslt_obj(
            XML::LibXSLT->new()
        );
    }

    return $self->_xslt_obj();
}

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->_mode($args->{mode});

    $self->_output_mode($args->{output_mode} || "filename");

    my $data_dir = $args->{'data_dir'} || dist_dir( 'XML-Grammar-Fortune' );

    $self->_data_dir($data_dir);

    return 0;
}

=head2 $self->run({ %args})

Runs the processor. If $mode is "validate", validates the document.

%args may contain:

=over 4

=item * xslt_params

Parameters for the XSLT stylesheet.

=item * input

Input source - depends on input_mode.

=item * output

Output destination - depends on output mode.

=back

=cut

sub run
{
    my $self = shift;
    my $args = shift;

    my $xslt_params = $args->{'xslt_params'} || {};

    my $output = $args->{'output'};
    my $input = $args->{'input'};

    my $mode = $self->_mode();

    if ($mode eq "validate")
    {
        my $doc = $self->_get_xml_parser->parse_file($input);

        my $code;
        $code = $self->_get_rng_schema()->validate($doc);

        if ($code)
        {
            die "Invalid file!";
        }

        return $code;
    }
    elsif ($mode eq "convert_to_html")
    {
        my $source = $self->_get_xml_parser->parse_file($input);

        my $results = $self->_get_xslt_stylesheet()->transform($source, %$xslt_params);

        if ($self->_output_mode() eq "string")
        {
            $$output .= $self->_get_xslt_stylesheet()->output_string($results);
        }
        else
        {
            open my $xhtml_out_fh, ">", $output;
            binmode ($xhtml_out_fh, ":utf8");
            print {$xhtml_out_fh}
                $self->_get_xslt_stylesheet()->output_string($results);
            close($xhtml_out_fh);
        }
    }
    
    return;
}

1; # End of XML::Grammar::Fortune

__END__

=head2 open

This function is introduced by Fatal. It is mentioned here, in order to settle 
L<Pod::Coverage> . Ignore.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

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

Copyright 2008 by Shlomi Fish

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

