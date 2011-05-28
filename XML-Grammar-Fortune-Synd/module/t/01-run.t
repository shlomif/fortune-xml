#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use File::Temp qw( tempdir );

use XML::RSS;

use List::Util qw(first);

my $temp_dir = tempdir( CLEANUP => 1 );

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
    "--yaml-data" => "$temp_dir/fort.yaml",
    "--atom-output" => "$temp_dir/fort.atom",
    "--rss-output" => "$temp_dir/fort.rss",
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

$rss->parsefile("$temp_dir/fort.rss");

my $item = first { $_->{'title'} =~ m{The Only Language} } @{$rss->{'items'}};

# TEST
ok ($item, "Item exists.");

# TEST
like (
    $item->{'content'}->{'encoded'},
    qr{<table class="irc-conversation">\s*<tbody>\s*<tr class="saying">\s*<td class="who">}ms,
    "Contains the table tag."
);

print $item;

