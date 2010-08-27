use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'XML::Grammar::Fortune::Synd',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/XML/Grammar/Fortune/Synd.pm',
    requires =>
    {
        'base' => 0,
        'Class::Accessor' => 0,
        'DateTime::Format::W3CDTF' => 0,
        'Exporter' => 0,
        'File::Spec' => 0,
        'Getopt::Long' => 0,
        'Heap::Binary' => 0,
        'Heap::Elem::Ref' => 0,
        'List::Util' => 0,
        'strict' => 0,
        'vars' => 0,
        'warnings' => 0,
        'XML::Feed' => 0,
        'XML::Grammar::Fortune' => 0,
        'XML::RSS' => "1.46",
        'YAML::Syck' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'XML-Grammar-Fortune-Synd-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
