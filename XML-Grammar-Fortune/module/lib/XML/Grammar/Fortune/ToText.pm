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
    _fortune
    _this_line
    ));


=head1 NAME

XML::Grammar::Fortune::ToText - convert the FortunesXML grammar to plaintext.

=head1 VERSION

Version 0.0300

=cut

our $VERSION = '0.0300';


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

sub _start_new_line
{
    my ($self) = @_;

    return $self->_out("\n");
}

sub _render_single_fortune_cookie
{
    my ($self, $fortune_node) = @_;

    $self->_fortune($fortune_node);

    my ($node) = $self->_fortune()->findnodes("raw|irc|screenplay|quote");

    my $method = sprintf("_process_%s_node", $node->localname());

    $self->$method($node);

    $self->_render_info_if_exists();

    return;
}

sub _output_next_fortune_delim
{
    my $self = shift;

    return $self->_out("%\n");
}

sub _do_nothing {}

sub _iterate_on_child_elems
{
    my ($self, $top_elem, $xpath, $args) = @_;
    
    my $process_cb = $args->{'process'};
    my $if_remainaing_meth = $args->{'if_more'};
    my $continue_cb = ($args->{'cont'} || \&_do_nothing);

    my $list = $top_elem->findnodes($xpath);

    while (my $elem = $list->shift())
    {
        $process_cb->($elem);
    }
    continue
    {
        $continue_cb->();

        if ($list->size())
        {
            $self->$if_remainaing_meth();
        }
    }

    return;
}

=head2 $self->run()

Runs the processor. If $mode is "validate", validates the document.

=cut

sub run
{
    my $self = shift;

    my $xml = XML::LibXML->new->parse_file($self->_input());

    $self->_iterate_on_child_elems(
        $xml, 
        "//fortune",
        {
            process => sub {
                return $self->_render_single_fortune_cookie(shift); 
            },
            if_more => '_output_next_fortune_delim',
        }
    );

    return;
}

sub _render_info_if_exists
{
    my ($self) = @_;

    if (() = $self->_fortune()->findnodes("descendant::info/*"))
    {
        $self->_render_info_node();
    }

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

    return;
}

sub _render_screenplay_paras
{
    my ($self, $portion) = @_;
    return $self->_render_portion_paras($portion, {para_is => "para"});
}

sub _handle_screenplay_portion
{
    my ($self, $portion) = @_;

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

        $self->_start_new_line;
    }

    return;
}

sub _process_screenplay_node
{
    my ($self, $play_node) = @_;

    my ($body_node) = $play_node->findnodes("body");

    $self->_iterate_on_child_elems(
        $body_node,
        "description|saying",
        {
            process => sub {
                return $self->_handle_screenplay_portion(shift);
            },
            if_more => '_start_new_line',
        }
    );

    return;
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
        $self->_start_new_line;
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

sub _append_different_formatting_node
{
    my ($self, $prefix, $suffix, $node) = @_;

    return 
        $self->_append_to_this_line(
            $prefix . $node->textContent() . $suffix
        );
}

sub _append_format_node
{
    my ($self, $delim, $node) = @_;

    return $self->_append_different_formatting_node($delim, $delim, $node);
}

{
    my @_highlights = (['/', [qw(em i)]], ['*', [qw(b strong)]]);

    my %_formats_map =
    (
        (
            map { my ($f, $tags) = @$_; map { $_ => [($f)x2] } @$tags } 
            @_highlights
        ),
        'inlinedesc' => ['[', ']'],
    );

    sub _get_node_formatting_delims
    {
        my ($self, $node) = @_;

        my $name = $node->localname();

        return exists($_formats_map{$name})
            ? $_formats_map{$name}
            : [(q{}) x 2]
            ;
    }
}

sub _handle_format_node
{
    my ($self, $node) = @_;

    $self->_append_different_formatting_node(
        @{$self->_get_node_formatting_delims($node)},
        $node,
    );

    return;
}

sub _render_para
{
    my ($self, $para) = @_;

    foreach my $node ($para->childNodes())
    {
        if ($node->nodeType() == XML_ELEMENT_NODE())
        {
            my $name = $node->localname();

            if ($name eq "br")
            {
                $self->_out_formatted_line();
            }
            elsif ($name eq "a")
            {
                $self->_append_different_formatting_node(
                    "[",
                    ("](". $node->getAttribute("href") . ")"),
                    $node
                );
            }
            else
            {
                $self->_handle_format_node($node);
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

sub _render_quote_list
{
    my ($self, $ul) = @_;

    my $is_bullets = ($ul->localname() eq "ul");

    my $idx = 1;

    $self->_iterate_on_child_elems(
        $ul,
        "li",
        {
            process => sub {
                my $li = shift;

                $self->_append_to_this_line(
                    ($is_bullets ? "*" : "$idx.") . " "
                );

                $self->_render_para($li);

                return;
            },
            cont => sub {
                $idx++;

                $self->_out_formatted_line();

                return;
            },
            if_more => '_start_new_line',
        }
    );

    return;
}

sub _render_quote_portion_paras
{
    my ($self, $node) = @_;

    $self->_render_portion_paras(
        $node, { para_is => "blockquote|p|ol|ul" }
    );

    return;
}

sub _render_quote_blockquote
{
    my ($self, $node) = @_;

    $self->_out("<<<\n\n");

    $self->_render_quote_portion_paras($node);   

    $self->_out("\n\n>>>");
}

sub _start_new_para
{
    my ($self) = @_;

    return $self->_out("\n\n");
}

sub _handle_portion_paragraph
{
    my $self = shift;
    my $para = shift;

    $self->_is_first_line(1);

    if (($para->localname() eq "ul") || ($para->localname() eq "ol"))
    {
        $self->_render_quote_list($para);
    }
    elsif ($para->localname() eq "blockquote")
    {
        $self->_render_quote_blockquote($para);
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

    return;
}

sub _render_portion_paras
{
    my ($self, $portion, $args) = @_;

    my $para_name = $args->{para_is};

    $self->_iterate_on_child_elems(
        $portion,
        $para_name,
        {
            process => sub {
                return $self->_handle_portion_paragraph(shift);
            },
            if_more => '_start_new_para',
        }
    );

    return;
}

sub _process_quote_node
{
    my ($self, $quote_node) = @_;

    my ($body_node) = $quote_node->findnodes("body");

    $self->_render_quote_portion_paras($body_node);   

    $self->_start_new_line;

    return;
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

sub _calc_info_field_processed_content
{
    my $self = shift;
    my $field_node = shift;

    my $content = $field_node->textContent();

    # Squash whitespace including newlines into a single space.
    $content =~ s{\s+}{ }g;

    # Remove leading and trailing space - it is not desirable here
    # because we want it formatted consistently.
    $content =~ s{\A\s+}{};
    $content =~ s{\s+\z}{};

    return $content;
}

sub _output_info_value
{
    my ($self, $string) = @_;

    return $self->_out((' ' x 4) . '-- ' . $string . "\n");
}

sub _out_info_field_node
{
    my ($self, $info_node, $field_node) = @_;

    my $name = $field_node->localname();
    my $value = $self->_calc_info_field_processed_content($field_node);

    if ($name eq "author")
    {
        $self->_output_info_value($value);
    }
    elsif (($name eq "work") || ($name eq "tagline"))
    {
        my $url = "";

        if ($field_node->hasAttribute("href"))
        {
            $url = " ( " . $field_node->getAttribute("href") . " )";
        }

        $self->_output_info_value($value.$url);
    }
    elsif ($name eq "channel")
    {
        my $channel = $field_node->textContent();
        my $network = $info_node->findnodes("network")->shift()->textContent();
        
        $self->_output_info_value( "$channel, $network" );
    }

    return;
}

sub _get_info_node_fields
{
    my ($self, $info_node) = @_;

    return
        reverse
        sort {
            $self->_info_field_value($a) <=> $self->_info_field_value($b)
        }
        $info_node->findnodes("*")
    ;

}

sub _render_info_node
{
    my ($self) = @_;

    my $fortune = $self->_fortune();

    $self->_start_new_line;

    my ($info_node) = $fortune->findnodes("descendant::info");

    foreach my $field_node ($self->_get_info_node_fields($info_node))
    {
        $self->_out_info_field_node($info_node, $field_node);
    }

    return;
}

1;

