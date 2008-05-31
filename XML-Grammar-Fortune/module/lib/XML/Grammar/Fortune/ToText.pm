package XML::Grammar::Fortune::ToText;

use warnings;
use strict;

use XML::LibXML;

use Carp ();

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(
    _mode
    _input
    _output
    ));


=head1 NAME

XML::Grammar::Fortune::ToText - convert the FortunesXML grammar to plaintext.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

TODO : Fill in.

=head1 FUNCTIONS

=head2 my $processor = XML::Grammar::Fortune::ToText->new({input => "path/to/file.xml", output => \*STDOUT,});

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

    $self->_input($args->{input});
    $self->_output($args->{output});

    return 0;
}

sub _out
{
    my $self = shift;

    print {$self->_output()} @_;

    return;
}

=head2 $self->run()

Runs the processor. If $mode is "validate", validates the document.

=cut

sub run
{
    my $self = shift;

    my $xml = XML::LibXML->new->parse_file($self->_input());

    my $fortunes_list = $xml->findnodes("//fortune");

    while (my $fortune = $fortunes_list->shift())
    {
        my ($raw_node) = $fortune->findnodes("raw");

        my ($text_node) = $raw_node->findnodes("body/text");

        my @text_childs = $text_node->childNodes();

        if (@text_childs != 1)
        {
            Carp::confess('@cdata is not 1');
        }

        my $cdata = $text_childs[0];

        if ($cdata->nodeType() != XML_CDATA_SECTION_NODE())
        {
            Carp::confess("Not a cdata");
        }

        my $value = $cdata->nodeValue();

        $value =~ s{\n+\z}{}g;
        $self->_out("$value\n");

        if (() = $fortune->findnodes("descendant::info/*"))
        {
            $self->_render_info($fortune);
        }
        # If there are more fortunes - output a separator.
        if ($fortunes_list->size())
        {
            $self->_out("%\n");
        }
    }

    return;
}

sub _render_info
{
    my ($self, $fortune) = @_;

    $self->_out("\n");

    my ($info) = $fortune->findnodes("descendant::info");
    
    my @fields = $info->findnodes("*");

    foreach my $field_node (@fields)
    {
        my $name = $field_node->localname();

        if ($name eq "author")
        {
            $self->_out((" " x 4) . "-- " . $field_node->textContent() . "\n");
        }
        elsif ($name eq "work")
        {
            my $url = "";
            if ($field_node->hasAttribute("href"))
            {
                $url = " ( " . $field_node->getAttribute("href") . " )";
            }
            $self->_out(
                  (" " x 4) . "-- "
                . $field_node->textContent()
                . $url
                . "\n"
            );
        }

    }   
}
1;

