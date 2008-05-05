use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
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
