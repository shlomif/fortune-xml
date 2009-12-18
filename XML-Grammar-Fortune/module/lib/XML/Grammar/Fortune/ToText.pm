package XML::Grammar::Fortune::ToText;

use warnings;
use strict;

use XML::LibXML;
use Text::Format;
use List::Util (qw(max));

use Carp ();

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(
    _formatter
    _is_first_line
    _mode
    _input
    _output
    _fortunes_list
    _fortune
    _this_line
    ));


=head1 NAME

XML::Grammar::Fortune::ToText - convert the FortunesXML grammar to plaintext.

=head1 VERSION

Version 0.0109

=cut

our $VERSION = '0.0109';


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

    $self->_formatter(
        Text::Format->new(
            {
                columns => 78,
                firstIndent => 0,
                leftMargin => 0,
            }
        )
    );

    $self->_this_line("");

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

    $self->_fortunes_list(scalar($xml->findnodes("//fortune")));

    while ($self->_fortune($self->_fortunes_list->shift()))
    {
        my ($raw_node) = $self->_fortune()->findnodes("raw|irc|screenplay|quote");

        if ($raw_node->localname() eq "raw")
        {
            $self->_process_raw_node($raw_node);
        }
        elsif ($raw_node->localname() eq "irc")
        {
            $self->_process_irc_node($raw_node);
        }
        elsif ($raw_node->localname() eq "screenplay")
        {
            $self->_process_screenplay_node($raw_node);
        }
        elsif ($raw_node->localname() eq "quote")
        {
            $self->_process_quote_node($raw_node);
        }
    }
    continue
    {
        # If there are more fortunes - output a separator.
        if ($self->_fortunes_list->size())
        {
            $self->_out("%\n");
        }
    }

    $self->_fortunes_list(undef);

    return;
}

sub _process_raw_node
{
    my ($self, $raw_node) = @_;

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

    if (() = $self->_fortune()->findnodes("descendant::info/*"))
    {
        $self->_render_info();
    }

    return;
}

sub _process_irc_node
{
    my ($self, $irc_node) = @_;

    my ($body_node) = $irc_node->findnodes("body");

    my @lines_list = $body_node->findnodes("saying|me_is|joins|leaves");
    
    use List::Util qw(max);

    my $longest_nick_len = 0;
    my @messages;
    foreach my $line (@lines_list)
    {
        if ($line->localname() eq "saying")
        {
            my $nick = $line->getAttribute("who");
            push @messages,
                {
                    type => "say",
                    nick => $nick,
                    msg => $line->textContent(),
                };

            $longest_nick_len = max($longest_nick_len, length($nick));
        }
        elsif ($line->localname() eq "me_is")
        {
            my $nick = $line->getAttribute("who");
            push @messages,
                {
                    type => "me_is",
                    nick => $nick,
                    msg => $line->textContent(),
                };
            
            $longest_nick_len = max($longest_nick_len, length("*"));
        }
        elsif ($line->localname() eq "joins")
        {
            my $nick = $line->getAttribute("who");
            push @messages,
                {
                    type => "joins",
                    nick => $nick,
                    msg => $line->textContent(),
                };
            
            $longest_nick_len = max($longest_nick_len, length("<--"));
        }
        elsif ($line->localname() eq "leaves")
        {
            my $nick = $line->getAttribute("who");
            push @messages,
                {
                    type => "leaves",
                    nick => $nick,
                    msg => $line->textContent(),
                };
            
            $longest_nick_len = max($longest_nick_len, length("-->"));
        }
        else
        {
            Carp::confess(
                'Unimplemented localname "' . $line->localname() . '"'
            );
        }
    }

=begin nothing

    {
        elsif (m{^[^\-]* ---\t(\S+) is now known as (\S+)})
        {
            my ($old_nick, $new_nick) = ($1, $2);
            push @messages, 
                {'type' => "change_nick", 'old' => $old_nick, 'new' => $new_nick};
            $longest_nick_len =
                max($longest_nick_len, length($old_nick), length($new_nick));
        }
        else
        {
           push @messages, {'type' => "raw", 'msg' => $_};
        }
    }

=end nothing

=cut

    my $formatter = 
        Text::Format->new(
            {
                columns => 72-1-2-$longest_nick_len,
                firstIndent => 0,
                leftMargin => 0,
            }
        );

    my $line_starts_at = $longest_nick_len
        + 1  # For the <
        + 1  # For the >
        + 1  # For the space at the beginning
        + 2  # For the space after the nick.
        ;

    my $nick_len_with_delim = $longest_nick_len+2;

    foreach my $m (@messages)
    {
        my %cmds = ("me_is" => "*", "joins" => "-->", "leaves" => "<--",);

        if ($m->{'type'} eq "say")
        {
            my @lines = ($formatter->format([$m->{'msg'}]));
            $self->_out(" " . sprintf("%${nick_len_with_delim}s", "<" . $m->{'nick'} . ">") . 
                "  " . $lines[0]);
            $self->_out(join("",
                    map { (" " x $line_starts_at) . $_ } 
                    @lines[1..$#lines]
                )
            );
        }
        elsif ($m->{'type'} eq "raw")
        {
            $self->_out($m->{'msg'}. "\n");
        }
        elsif ($m->{'type'} eq "change_nick")
        {
            $self->_out((" " x ($line_starts_at)) .
                $m->{'old'} ." is now known as " . $m->{'new'} . "\n");
        }
        elsif (exists($cmds{$m->{'type'}}))
        {
            my @lines = $formatter->format(
                    [$m->{'nick'} . " " . $m->{'msg'}]
            );

            $self->_out(" " . sprintf("%${nick_len_with_delim}s", 
                    $cmds{$m->{'type'}}) . "  " . $lines[0]);

            $self->_out(join("",
                    map { (" " x $line_starts_at) . $_ } 
                    @lines[1..$#lines]
                )
            );
        }
    }

    if (() = $self->_fortune()->findnodes("descendant::info/*"))
    {
        $self->_render_info();
    }

    return;
}

sub _render_screenplay_paras
{
    my ($self, $portion) = @_;
    return $self->_render_portion_paras($portion, {para_is => "para"});
}

sub _process_screenplay_node
{
    my ($self, $play_node) = @_;

    my ($body_node) = $play_node->findnodes("body");

    my $portions_list = $body_node->findnodes("description|saying");

    
    while (my $portion = $portions_list->shift())
    {
        if ($portion->localname() eq "description")
        {
            $self->_this_line("[");

            $self->_render_screenplay_paras($portion);

            $self->_out("]\n");
        }
        else # localname() is "saying"
        {
            $self->_this_line($portion->getAttribute("character") . ": ");

            $self->_render_screenplay_paras($portion);

            $self->_out("\n");
        }
    }
    continue
    {
        if ($portions_list->size())
        {
            $self->_out("\n");
        }
    }

    if (() = $self->_fortune()->findnodes("descendant::info/*"))
    {
        $self->_render_info();
    }    
}

sub _out_formatted_line
{
    my $self = shift;
    my $text = $self->_this_line();

    $text =~ s{\A\n+}{}ms;
    $text =~ s{\n+\z}{}ms;
    $text =~ s{\s+}{ }gms;

    if ($self->_is_first_line())
    {
        $self->_is_first_line(0);
    }
    else
    {
        $self->_out("\n");
    }

    my $output_string = $self->_formatter->format($text);

    # Text::Format inserts a new line - remove it.
    chomp($output_string);

    $self->_out($output_string);

    $self->_this_line("");

    return;
}

sub _append_to_this_line
{
    my ($self, $more_text) = @_;

    $self->_this_line($self->_this_line() . $more_text);
}

sub _render_para
{
    my ($self, $para) = @_;

    foreach my $node ($para->childNodes())
    {
        if ($node->nodeType() == XML_ELEMENT_NODE())
        {
            if ($node->localname() eq "br")
            {
                $self->_out_formatted_line();
            }
            else
            {
                $self->_append_to_this_line($node->textContent());
            }
        }
        elsif ($node->nodeType() == XML_TEXT_NODE())
        {
            my $node_text = $node->textContent();

            # Intent: format the text.
            # Trim leading and trailing nelines.
            $node_text =~ s{\A\n+}{}ms;
            $node_text =~ s{\n+\z}{}ms;

            # Convert a sequence of space to a single space.
            $node_text =~ s{\s+}{ }gms;

            $self->_append_to_this_line($node_text);
        }
    }
}

sub _render_quote_ul
{
    my ($self, $ul) = @_;

    my $items_list = $ul->findnodes("li");

    while (my $li = $items_list->shift())
    {
        my $node_text = $li->textContent();

        # Intent: format the text.
        # Trim leading and trailing nelines.
        $node_text =~ s{\A\n+}{}ms;
        $node_text =~ s{\n+\z}{}ms;

        # Convert a sequence of space to a single space.
        $node_text =~ s{\s+}{ }gms;

        $self->_out("* $node_text");
    }
    continue
    {
        if ($items_list->size())
        {
            $self->_out("\n\n");
        }
    }

    return;
}

sub _render_portion_paras
{
    my ($self, $portion, $args) = @_;

    my $para_name = $args->{para_is};

    my $paragraphs = $portion->findnodes($para_name);

    while (my $para = $paragraphs->shift())
    {
        $self->_is_first_line(1);

        if ($para->localname() eq "ul")
        {
            $self->_render_quote_ul($para);
        }
        else
        {
            $self->_render_para($para);
        }

        if ($self->_this_line() =~ m{\S})
        {
            $self->_out_formatted_line();
            $self->_this_line("");
        }
    }
    continue
    {
        if ($paragraphs->size())
        {
            $self->_out("\n\n");
        }
    }
}

sub _process_quote_node
{
    my ($self, $quote_node) = @_;

    my ($body_node) = $quote_node->findnodes("body");

    $self->_render_portion_paras($body_node, { para_is => "p|ul" });

    $self->_out("\n");

    if (() = $self->_fortune()->findnodes("descendant::info/*"))
    {
        $self->_render_info();
    }
}

my @info_fields_order = (qw(work author channel tagline));

my %info_fields_order_map =
(map { $info_fields_order[$_] => $_+1 } (0 .. $#info_fields_order));

sub _info_field_value
{
    my $self = shift;
    my $field = shift;

    return $info_fields_order_map{$field->localname()} || (-1);
}

sub _render_info
{
    my ($self) = @_;

    my $fortune = $self->_fortune();

    $self->_out("\n");

    my ($info) = $fortune->findnodes("descendant::info");
    
    my @fields = $info->findnodes("*");

    foreach my $field_node (
        reverse(
        sort { 
            $self->_info_field_value($a) <=> $self->_info_field_value($b)
        }
        @fields)
    )
    {
        my $name = $field_node->localname();

        if ($name eq "author")
        {
            $self->_out((" " x 4) . "-- " . $field_node->textContent() . "\n");
        }
        elsif (($name eq "work") || ($name eq "tagline"))
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
        elsif ($name eq "channel")
        {
            my $channel = $field_node->textContent();
            my $network = $info->findnodes("network")->shift()->textContent();
            
            $self->_out(
                (" " x 4) . "-- "
                . "$channel, $network"
                . "\n"
            );
        }
    }   
}

1;

