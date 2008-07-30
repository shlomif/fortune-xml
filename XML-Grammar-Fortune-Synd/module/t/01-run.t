#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

# TEST
ok (!system(
    $^X,
    "-MXML::Grammar::Fortune::Synd::App",
    "-e",
    "run()",
    "--",
    "--dir" => "t/data/fortune-synd-1",
    qw(
        --xml-file irc-conversation-4-several-convos.xml
        --xml-file screenplay-fort-sample-1.xml
    ),
    "--yaml-data" => "t/data/out-fortune-synd-1/fort.yaml",
    "--atom-output" => "t/data/out-fortune-synd-1/fort.atom",
    "--rss-output" => "t/data/out-fortune-synd-1/fort.rss",
    "--master-url" => "http://www.fortunes.tld/My-Fortunes/",
    "--title" => "My Fortune Feeds",
    "--tagline" => "My Fortune Feeds",
    "--author" => "shlomif\@iglu.org.il (Shlomi Fish)",
));

