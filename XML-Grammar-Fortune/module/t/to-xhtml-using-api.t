#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;
use Test::Differences;

use File::Spec;
use Encode;

use XML::Grammar::Fortune;

# TEST:$num_texts=12

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
        quote-fort-sample-10-with-hyperlink
    ));

sub read_file
{
    my $path = shift;

    open my $in, "<", $path
        or die "Cannot open '$path' for reading";
    binmode $in, ":utf8";
    my $contents;
    {
        local $/;
        $contents = <$in>
    }
    close($in);
    return $contents;
}

sub normalize_xml
{
    my $results = shift;

    my $unicode = decode("UTF-8", $results);

    # Remove leading space (indentation), which seems to vary between 
    # different versions of XML-LibXSLT and/or libxslt
    $unicode =~ s{^[ \t]+}{}gms;

    return $unicode;
}

foreach my $fn_base (@tests)
{
    my $filename = "./t/data/xml/$fn_base.xml";

    my $converter =
        XML::Grammar::Fortune->new(
            {
                data_dir => "./extradata/",
                mode => "convert_to_html",
                _output_mode => "string",
            }
        );

    my $results_buffer = "";

    $converter->run(
        {
            input => $filename,
            output => \$results_buffer,
        }
    );

    # TEST*$num_texts
    eq_or_diff (
        normalize_xml($results_buffer),
        read_file("./t/data/xhtml-results/$fn_base.xhtml"),
        "Testing for Good XSLTing of '$fn_base'",
    );
}

{
    my $converter =
        XML::Grammar::Fortune->new(
            {
                mode => "convert_to_html",
                _output_mode => "string",
                data_dir => "./extradata/",
            }
        );

    foreach my $fn_base (@tests)
    {
        my $filename = "./t/data/xml/$fn_base.xml";

        my $results_buffer = "";

        $converter->run(
            {
                input => $filename,
                output => \$results_buffer,
            }
        );

        # TEST*$num_texts
        eq_or_diff (
            normalize_xml($results_buffer),
            read_file("./t/data/xhtml-results/$fn_base.xhtml"),
            "Testing for Good XSLTing of '$fn_base'",
        );
    }

}
1;

