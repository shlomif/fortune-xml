use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'XML::Grammar::Fortune',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/XML/Grammar/Fortune.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'XML-Grammar-Fortune-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
