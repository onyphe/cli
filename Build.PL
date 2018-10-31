#
# $Id: Build.PL,v 635de629083a 2018/10/30 17:14:02 gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Metabrik::Client::Onyphe',
   license => 'bsd',
   dist_author => 'ONYPHE <contact_at_onyphe.io>',
   dist_version_from => 'lib/Metabrik/Client/Onyphe.pm',
   requires => {
      'perl' => '5.6.1',
      'Metabrik' => '1.31',
      'Metabrik::Repository' => '1.31',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
   script_files => [ qw(bin/onyphe) ],
);

$builder->create_build_script;
