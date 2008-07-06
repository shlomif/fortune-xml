#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use XML::Feed;
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

__PACKAGE__->mk_accessors(qw(
        _xml_parser
        _file_doms
        _date_formatter
        xml_files
    ));

sub new
{
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);

    $self->_xml_parser(XML::LibXML->new());
    $self->_date_formatter(DateTime::Format::W3CDTF->new());
    $self->_file_doms(+{});

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

    return
    {
        'recent_ids' => [reverse(@recent_ids)],
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

my $syndicator = XML::Grammar::Fortune::Synd->new({ xml_files => \@xml_files});


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
print join(",", map { $_->val->id() } @{$recent_ids_struct->{recent_ids}}), "\n";


