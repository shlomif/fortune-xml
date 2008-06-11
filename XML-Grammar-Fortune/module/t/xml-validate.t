use strict;
use warnings;

use Test::More tests => 9;                      # last test to print

use XML::LibXML;

# TEST:$num_tests=9
my @inputs = (qw(
        irc-conversation-1
        irc-conversation-2-with-slash-me
        irc-conversation-3-with-join-unjoin
        irc-conversation-4-several-convos
        irc-convos-and-raw-fortunes-1
        quote-fort-sample-1
        quote-fort-sample-2-with-brs
        quote-fort-sample-4-ul
        screenplay-fort-sample-1
    ));

my $rngschema = XML::LibXML::RelaxNG->new(
        location => "./extradata/fortune-xml.rng" 
    );



foreach my $fn_base (@inputs)
{
    my $filename = "./t/data/xml/$fn_base.xml";
    my $doc = XML::LibXML->new->parse_file($filename);

    my $code;
    $code = $rngschema->validate($doc);

    # TEST*$num_tests
    ok ((defined($code) && ($code == 0)),
        "The validation of '$filename' succeeded.") ||
        diag("\$@ == $@");

}
