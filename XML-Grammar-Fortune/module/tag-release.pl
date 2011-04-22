#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) = 
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () } 
    io->file('lib/XML/Grammar/Fortune.pm')->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my $mini_repos_base = 'https://svn.berlios.de/svnroot/repos/web-cpan/XML-Grammar-Fortune';

my @cmd = (
    "svn", "copy", "-m",
    "Tagging the XML-Grammar-Fortune release as $version",
    "$mini_repos_base/trunk",
    "$mini_repos_base/tags/releases/cpan/$version",
);

print join(" ", map { /\s/ ? qq{"$_"} : $_ } @cmd), "\n";
exec(@cmd);

