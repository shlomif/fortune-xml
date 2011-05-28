#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use File::Temp qw( tempdir );

use XML::RSS;
use File::Copy;

use List::Util qw(first);

my $temp_dir = tempdir( CLEANUP => 1 );

my $yaml_data_fn = "$temp_dir/fort.yaml";

copy("t/data/fortune-synd-eliminate-old-ids-1/fort.yaml", $yaml_data_fn);

my @cmd_line = (
    $^X,
    "-MXML::Grammar::Fortune::Synd::App",
    "-e",
    "run()",
    "--",
    "--dir" => "t/data/fortune-synd-eliminate-old-ids-1/",
    qw(
        --xml-file irc-conversation-4-several-convos.xml
        --xml-file screenplay-fort-sample-1.xml
    ),
    "--yaml-data" => $yaml_data_fn,
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

sub _slurp
{
    my $filename = shift;

    open my $in, "<", $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

# TODO : use a YAML parser etc., but I'm lazy.
{
    my $content = _slurp($yaml_data_fn);

    my @matches = ($content =~ m{let-me-wikipedia-it}g);
    
    # TEST
    is (scalar(@matches), 1, "ID exists only in one place.");
}
