#===============================================================================
#
#         FILE:  xml-validate.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Shlomi Fish (SHLOMIF), <shlomif@iglu.org.il>
#      COMPANY:  None
#      VERSION:  1.0
#      CREATED:  05/05/08 13:34:28 IDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 8;                      # last test to print

use XML::LibXML;

# TEST:$num_tests=8
my @inputs = (qw(
        irc-conversation-1
        irc-conversation-2-with-slash-me
        irc-conversation-3-with-join-unjoin
        irc-conversation-4-several-convos
        irc-convos-and-raw-fortunes-1
        quote-fort-sample-1
        quote-fort-sample-2-with-brs
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
