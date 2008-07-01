#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use XML::Feed;
use YAML::Syck;
use XML::LibXML;

my $input;

GetOptions(
    'i|input=s' => \$input,
);

my $xml = XML::LibXML->new->parse_file($input);


