#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use XML::RSS;

use List::Util qw(first);

my @cmd_line = (
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
);

sub print_cmd_line
{
    open my $out_fh, ">", "file.bash";
    print {$out_fh} join(" ", map { qq{"$_"} } @cmd_line);
    close($out_fh);
}

print_cmd_line();

# TEST
ok (!system(@cmd_line));

my $rss = XML::RSS->new(version => "2.0");

$rss->parsefile("t/data/out-fortune-synd-1/fort.rss");

my $item = first { $_->{'title'} =~ m{The Only Language} } @{$rss->{'items'}};

# TEST
ok ($item, "Item exists.");
# \s*<td class="who">
# TEST
like (
    $item->{'content'}->{'encoded'},
    qr{<table class="irc-conversation">\s*<tbody>\s*<tr class="saying">}ms,
    "Contains the table tag."
);

print $item;

