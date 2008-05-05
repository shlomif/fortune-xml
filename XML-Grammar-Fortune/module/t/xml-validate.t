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

use Test::More tests => 4;                      # last test to print

use XML::LibXML;

my @inputs = (qw(
        irc-conversation-1
        irc-conversation-2-with-slash-me
        irc-conversation-3-with-join-unjoin
        irc-conversation-4-several-convos
    ));

my $rngschema = XML::LibXML::RelaxNG->new(
        location => "./extradata/fortune-xml.rng" 
    );


# TEST:$num_tests=4

foreach my $fn_base (@inputs)
{
    my $doc = XML::LibXML->new->parse_file("./t/data/xml/$fn_base.xml");

    my $code;
    $code = $rngschema->validate($doc);

    # TEST*$num_tests
    ok ((defined($code) && ($code == 0)),
        "The validation succeeded.") ||
        diag("\$@ == $@");

}
