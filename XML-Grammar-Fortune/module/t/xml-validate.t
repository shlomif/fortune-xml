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

use Test::More tests => 1;                      # last test to print

use XML::LibXML;

my $doc = XML::LibXML->new->parse_file("./t/data/xml/irc-conversation-1.xml");

my $rngschema = XML::LibXML::RelaxNG->new(
    location => "./extradata/fortune-xml.rng" 
);

my $code;
$code = $rngschema->validate($doc);

# TEST
ok ((defined($code) && ($code == 0)),
    "The validation succeeded.") ||
    diag("\$@ == $@");

