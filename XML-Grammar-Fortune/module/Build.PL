use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use XML::Grammar::Builder;

my $builder = XML::Grammar::Builder->new(
    module_name         => 'XML::Grammar::Fortune',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/XML/Grammar/Fortune.pm',
    requires => {
        'Class::Accessor' => 0,
        'File::Spec' => 0,
        'perl' => "5.008",
        'Text::Format' => 0,
        'vars' => 0,
        'warnings' => 0,
        'XML::LibXML' => 0,
        'XML::LibXSLT' => 0,
    },
    build_requires =>
    {
        'IO::String' => 0,
        'Test::Differences' => 0,
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'XML-Grammar-Fortune-*' ],
    create_makefile_pl => 'passthrough',
    meta_merge =>
    {
        resources =>
        {
            repository => "https://svn.berlios.de/svnroot/repos/web-cpan/XML-Grammar-Fortune/",
            homepage => "http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/",
            "Freshmeat" => "http://freshmeat.net/projects/fortune-xml",
        },
    },
);

$builder->create_build_script();
