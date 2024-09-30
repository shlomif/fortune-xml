#!/usr/bin/perl

use 5.014;
use strict;
use warnings;
use utf8;

use Encode qw/ decode /;
use Test::More tests => 19;
use Test::Differences qw/ eq_or_diff /;

use XML::Grammar::Fortune::ToText ();

use Path::Tiny qw/ path tempdir /;

# TEST:$num_texts=19

my @tests = (
    qw(
        raw-fort-empty-info-1
        raw-fort-with-info-1
        irc-conversation-1
        irc-conversation-3-with-join-unjoin
        irc-conversation-5-with-see-also
        quote-fort-sample-2-with-brs
        quote-fort-sample-3-more-than-one-para
        quote-fort-sample-4-ul
        quote-fort-sample-5-ol
        quote-fort-sample-6-with-bold
        quote-fort-sample-7-with-italics
        quote-fort-sample-8-with-em-and-strong
        quote-fort-sample-9-with-blockquote
        quote-fort-sample-10-with-hyperlink
        quote-fort-sample-11-with-work-elem-spanning-several-lines
        screenplay-fort-sample-1
        screenplay-fort-sample-2-with-italics
        screenplay-fort-sample-2-long-line
        screenplay-fort-sample-3-with-inlinedesc
    )
);

my $tempdir = tempdir();
foreach my $fn_base (@tests)
{
    my $xml_fn = "./t/data/xml/$fn_base.xml";
    my $buffer = "";

    my $out_fn = "./t/data/text-results/$fn_base.txt";
    my $outp   = path($out_fn);

    # if ( not -e $out_fn )
    open my $out, ">:encoding(UTF-8)", \$buffer;
    XML::Grammar::Fortune::ToText->new( { input => $xml_fn, output => $out } )
        ->run();
    close($out);

    if ( $ENV{DECODE} )
    {
        $buffer = decode( 'utf-8', $buffer );
    }

    # TEST*$num_texts
    eq_or_diff(
        $buffer,
        scalar( $outp->slurp_utf8 ),
        "Testing for Good Conversion to Text of '$fn_base'",
    );
}

1;
