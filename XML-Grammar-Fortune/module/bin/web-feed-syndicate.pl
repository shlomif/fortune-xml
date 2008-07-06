#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use XML::LibXML;
use DateTime::Format::W3CDTF;

package XML::Grammar::Fortune::Synd::Heap::Elem;

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(
    date
    id
    idx
    file
    ));

# "All problems in computer science can be solved by 
# adding another level of indirection;"
# -- http://en.wikipedia.org/wiki/Abstraction_layer
sub cmp
{
    my ($self, $other) = @_;
    return
    (
        ($self->date()->compare($other->date()))
            ||
        ($self->idx() <=> $other->idx())
    )
    ;
}

package XML::Grammar::Fortune::Synd;

use base 'Class::Accessor';

use YAML::Syck;
use Heap::Elem::Ref (qw(RefElem));
use Heap::Binary;
use XML::Feed;
use XML::Grammar::Fortune;

__PACKAGE__->mk_accessors(qw(
        _xml_parser
        _file_doms
        _date_formatter
        xml_files
        url_callback
        _file_processors
    ));

sub new
{
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);

    $self->_xml_parser(XML::LibXML->new());
    $self->_date_formatter(DateTime::Format::W3CDTF->new());
    $self->_file_doms(+{});
    $self->_file_processors(+{});

    return $self;
}

sub get_most_recent_ids
{
    my ($self, $args) = @_;

    my $scripts_hash_filename = $args->{'yaml_persistence_file'};
    my $scripts_hash_fn_out =   $args->{'yaml_persistence_file_out'};
    my $xmls_dir = $args->{xmls_dir};


    my $persistent_data = LoadFile($scripts_hash_filename);

    if (!exists($persistent_data->{'files'}))
    {
        $persistent_data->{'files'} = +{};
    }

    my $scripts_hash = $persistent_data->{'files'};

    my $ids_heap = Heap::Binary->new();

    my $ids_heap_count = 0;

    my $ids_limit = 20;

    foreach my $file (@{$self->xml_files()})
    {
        my $xml = $self->_xml_parser->parse_file(
            "$xmls_dir/$file",
        );

        $self->_file_doms->{$file} = $xml;

        my @fortune_elems = $xml->findnodes("//fortune");

        my @ids = (map { $_->getAttribute("id") } @fortune_elems);

        my $id_count = 1;

        IDS_LOOP:
        foreach my $id (@ids)
        {
            if (! exists($scripts_hash->{$file}->{$id}))
            {
                $scripts_hash->{$file}->{$id} =
                {
                    'date' => $self->_date_formatter->format_datetime(
                        DateTime->now(),
                    ),
                };
            }

            my $date = $self->_date_formatter->parse_datetime(
                $scripts_hash->{$file}->{$id}->{'date'},
            );

            $ids_heap->add(
                RefElem(
                    XML::Grammar::Fortune::Synd::Heap::Elem->new(
                        {
                            date => $date,
                            idx => $id_count,
                            id => $id,
                            file => $file,
                        }
                    )
                )
            );

            if (++$ids_heap_count > $ids_limit)
            {
                $ids_heap->extract_top();
                $ids_heap_count--;
            }
        }
        continue
        {
            $id_count++;
        }
    }

    my @recent_ids = ();

    # TODO : Should we reverse this?
    while (defined(my $id_obj = $ids_heap->extract_top()))
    {
        push @recent_ids, $id_obj;
    }
    DumpFile($scripts_hash_fn_out, $persistent_data);

    my $feed = XML::Feed->new("Atom");

    # Now fill the XML-Feed object:
    {

        foreach my $id_obj (map { $_->val() } @recent_ids)
        {
            my $file_dom =
                $self->_file_doms()->{$id_obj->file()};

            my ($fortune_dom) =
                $file_dom->findnodes("descendant::fortune[\@id='". $id_obj->id() . "']");

            my $entry = XML::Feed::Entry->new(
                "Atom"
            );

            $entry->title(
                $fortune_dom->findnodes("meta/title")->get_node(0)->textContent()
            );

            $entry->link(
                $self->url_callback()->(
                    $self, 
                    {
                        id_obj => $id_obj,
                    }
                ),
            );

            my $base_fn = $id_obj->file();
            $base_fn =~ s{\.[^\.]*\z}{}ms;
            $entry->id($base_fn . "--" . $id_obj->id());

            $entry->issued($id_obj->date());

            {
                $self->_file_processors()->{$id_obj->file()} ||=
                    XML::Grammar::Fortune->new(
                        {
                            mode => "convert_to_html",
                            input => "$xmls_dir/".$id_obj->file(),
                            output_mode => "string",
                        }
                    );

                my $file_processor =
                    $self->_file_processors()->{$id_obj->file()};

                my $content = "";

                $file_processor->run(
                    {
                        xslt_params =>
                        {
                            'fortune.id' => "'" . $id_obj->id() . "'",
                        },
                        output => \$content,
                    }
                );

                $entry->content(
                    XML::Feed::Content->new(
                        {
                            type => "text/html",
                            body => $content,
                        },
                    )
                );
            }

            $feed->add_entry(
                $entry
            );
        }
    }
    return
    {
        'recent_ids' => [reverse(@recent_ids)],
        'feeds' =>
        {
            'Atom' => $feed,
        },
    };
}

package main;

my $input;

GetOptions(
    'i|input=s' => \$input,
);

my @xml_files = (qw(
        friends.xml
        joel-on-software.xml
        nyh-sigs.xml
        osp_rules.xml
        paul-graham.xml
        shlomif-fav.xml
        shlomif.xml
        subversion.xml
        tinic.xml
    ));

my $syndicator = XML::Grammar::Fortune::Synd->new(
    { 
        xml_files => \@xml_files,
        url_callback => sub {
            my ($self, $args) = @_;

            my $id_obj = $args->{id_obj};

            my $base_fn = $id_obj->file();

            $base_fn =~ s{\.[^\.]*\z}{}ms;

            return 
                  "http://www.shlomifish.org/humour/fortunes/"
                . $base_fn . ".html" . "#" . $id_obj->id()
                ;
        }
    }
);


my $recent_ids_struct = $syndicator->get_most_recent_ids(
       {
            yaml_persistence_file => "shlomif-ids-data.yaml",
            yaml_persistence_file_out => "shlomif-ids-data.yaml",
            xmls_dir => "forts.old",
        }
    );

$recent_ids_struct = $syndicator->get_most_recent_ids(
    {
        yaml_persistence_file => "shlomif-ids-data.yaml",
        yaml_persistence_file_out => "shlomif-ids-data-new.yaml",
        xmls_dir => "forts.new"
    }
);
# print join(",", map { $_->val->id() } @{$recent_ids_struct->{recent_ids}}), "\n";
print $recent_ids_struct->{'feeds'}->{'Atom'}->as_xml();
