#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Differences;

use File::Spec;

use XML::LibXML;
use XML::LibXSLT;

# TEST:$num_texts=11

my @tests = (qw(
        irc-conversation-4-several-convos
        irc-convos-and-raw-fortunes-1
        raw-fort-empty-info-1
        quote-fort-sample-1
        quote-fort-sample-2-with-brs
        screenplay-fort-sample-1
        quote-fort-sample-4-ul
        quote-fort-sample-5-ol
        quote-fort-sample-6-with-bold
        quote-fort-sample-7-with-italics
        quote-fort-sample-8-with-em-and-strong
    ));

my $parser = XML::LibXML->new();
my $xslt = XML::LibXSLT->new();

my $style_doc = $parser->parse_file("./extradata/fortune-xml-to-html.xslt");
my $stylesheet = $xslt->parse_stylesheet($style_doc);

sub read_file
{
    my $path = shift;

    open my $in, "<", $path;
    binmode $in, ":utf8";
    my $contents;
    {
        local $/;
        $contents = <$in>
    }
    close($in);
    return $contents;
}

foreach my $fn_base (@tests)
{
    my $filename = "./t/data/xml/$fn_base.xml";

    open my $xml_in, "<", $filename;
    my $source = $parser->parse_fh($xml_in);
    close($xml_in);

    my $results = $stylesheet->transform($source);

    # TEST*$num_texts
    eq_or_diff (
        $stylesheet->output_string($results),
        read_file("./t/data/xhtml-results/$fn_base.xhtml"),
        "Testing for Good XSLTing of '$fn_base'",
    );
}

1;

