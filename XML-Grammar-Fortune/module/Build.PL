use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

use File::Find;

sub data_inc
{
    return "/usr/share/perl5/data/modules/XML-Grammar-Fortune/data";
}

my @extradata_files;

sub filter_files
{
    my $filename = $File::Find::name;
    if ((-f $filename) && ($filename =~ /\.(?:mod|xslt|dtd|ent|cat|jpg|rng|xcf\.bz2)$/))
    {
        push @extradata_files, $filename;
    }
}

find({ wanted => \&filter_files, no_chdir => 1}, "extradata");

my $builder = Test::Run::Builder->new(
    module_name         => 'XML::Grammar::Fortune',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/XML/Grammar/Fortune.pm',
    requires => {
        'Class::Accessor' => 0,
        'File::Spec' => 0,
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
    install_path =>
    {
        extradata => data_inc(),
    },
    extradata_files =>
    {
        (map { $_ => $_ } @extradata_files),
    },
);

$builder->add_build_element('extradata');
$builder->install_path->{'extradata'} = ($builder->prefix() || "/usr") . "/data/modules/XML-Grammar-Fortune/data";

$builder->config_data('extradata_install_path' => [$builder->install_path->{'extradata'}]);

$builder->create_build_script();
