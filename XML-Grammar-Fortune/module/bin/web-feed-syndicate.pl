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
    script
    ));

# "All problems in computer science can be solved by 
# adding another level of indirection;"
# -- http://en.wikipedia.org/wiki/Abstraction_layer
sub cmp
{
    my ($self, $other) = @_;
    return $self->date()->compare($other->date());
}

package main;


my $input;

GetOptions(
    'i|input=s' => \$input,
);

my $xml_parser = XML::LibXML->new;

my $date_formatter = DateTime::Format::W3CDTF->new();

my $scripts_hash_filename = "ids-data.yaml";

my $scripts_hash = LoadFile($scripts_hash_filename);

my @scripts = (qw(irc-3));

my $ids_heap = Heap::Binary->new();

my $ids_heap_count = 0;

my $ids_limit = 20;


foreach my $script (@scripts)
{
    my $xml = $xml_parser->parse_file("t/data/web-feed-synd/before/$script.xml");

    my @fortune_elems = $xml->findnodes("//fortune");

    my @ids = (map { $_->getAttribute("id") } @fortune_elems);

    IDS_LOOP:
    foreach my $id (@ids)
    {
        if (! exists($scripts_hash->{$script}->{$id}))
        {
            $scripts_hash->{$script}->{$id} =
            {
                'date' => $date_formatter->format_datetime(
                    DateTime->now(),
                ),
            };
        }

        my $date = $date_formatter->parse_datetime(
            $scripts_hash->{$script}->{$id}->{'date'},
        );

        $ids_heap->add(
            RefElem(
                XML::Grammar::Fortune::Synd::Heap::Elem->new(
                    {
                        date => $date,
                        id => $id,
                        script => $script,
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
}

my @recent_ids = ();

# TODO : Should we reverse this?
while (defined(my $id_obj = $ids_heap->extract_top()))
{
    push @recent_ids, $id_obj;
}

print join(",", map { $_->val->id() } @recent_ids), "\n";

DumpFile($scripts_hash_filename, $scripts_hash);

