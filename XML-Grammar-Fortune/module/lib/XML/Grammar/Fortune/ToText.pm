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
        my ($text_node) = $fortune->findnodes("raw/body/text");

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
        print {$self->_output()} "$value\n";
        # If there are more fortunes - output a separator.
        if ($fortunes_list->size())
        {
            print {$self->_output()} "%\n";
        }
    }

    return;
}

1;

