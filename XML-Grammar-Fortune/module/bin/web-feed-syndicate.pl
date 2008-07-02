#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use XML::Feed;
use YAML::Syck;
use XML::LibXML;
use DateTime::Format::W3CDTF;
use Heap::Elem::Ref (qw(RefElem));
use Heap::Binary;

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

package main;


my $input;

GetOptions(
    'i|input=s' => \$input,
);

my $xml_parser = XML::LibXML->new;

my $date_formatter = DateTime::Format::W3CDTF->new();

sub get_most_recent_ids
{
    my ($self, $args) = @_;

    my $scripts_hash_filename = $args->{'yaml_persistence_file'};
    my $scripts_hash_fn_out =   $args->{'yaml_persistence_file_out'};
    my $xmls_dir = $args->{xmls_dir};
    my @xml_files = @{$args->{xml_files}};


    my $persistent_data = LoadFile($scripts_hash_filename);

    if (!exists($persistent_data->{'files'}))
    {
        $persistent_data->{'files'} = +{};
    }

    my $scripts_hash = $persistent_data->{'files'};

    my $ids_heap = Heap::Binary->new();

    my $ids_heap_count = 0;

    my $ids_limit = 20;

    foreach my $file (@xml_files)
    {
        my $xml = $xml_parser->parse_file(
            "$xmls_dir/$file",
        );

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
                    'date' => $date_formatter->format_datetime(
                        DateTime->now(),
                    ),
                };
            }

            my $date = $date_formatter->parse_datetime(
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

    return
    {
        'recent_ids' => [reverse(@recent_ids)],
    };
}

if (0)
{
    my $recent_ids_struct = get_most_recent_ids(undef,
        {
            yaml_persistence_file => "ids-data.yaml",
            yaml_persistence_file_out => "ids-data.yaml",
            xml_files => [qw(irc-3.xml)],
            xmls_dir => "t/data/web-feed-synd/before/"
        }
    );
}

my $recent_ids_struct = get_most_recent_ids(undef,
    {
        yaml_persistence_file => "ids-data.yaml",
        yaml_persistence_file_out => "ids-data-new.yaml",
        xml_files => [qw(irc-3.xml)],
        xmls_dir => "t/data/web-feed-synd/after/"
    }
);
print join(",", map { $_->val->id() } @{$recent_ids_struct->{recent_ids}}), "\n";


