#!/bin/bash

# This script reproduces a sample problem with the feeds not validating.
#

"/usr/bin/perl5.16.3" "-MXML::Grammar::Fortune::Synd::App" "-e" "run()" "--" "--dir" "t/data/fortune-synd-eliminate-old-ids-1/" "--xml-file" "irc-conversation-4-several-convos.xml" "--xml-file" "screenplay-fort-sample-1.xml" "--yaml-data" "/home/shlomif/tmp/woj80J7hqo/fort.yaml" "--atom-output" "/home/shlomif/tmp/woj80J7hqo/fort.atom" "--rss-output" "/home/shlomif/tmp/woj80J7hqo/fort.rss" "--master-url" "http://www.fortunes.tld/My-Fortunes/" "--title" "My Fortune Feeds" "--tagline" "My Fortune Feeds" "--author" "shlomif@iglu.org.il (Shlomi Fish)"
