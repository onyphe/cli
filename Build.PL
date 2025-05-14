#
# $Id: Build.PL,v 604fb44b35f9 2025/03/27 09:23:31 gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Onyphe',
   license => 'bsd',
   dist_author => 'ONYPHE <contact_at_onyphe.io>',
   dist_version_from => 'lib/Onyphe.pm',
   requires => {
      'Mojolicious' => 0,
      'Config::INI::Tiny' => 0,
      'Tie::IxHash' => 0,
      'LWP::Protocol::https' => 0,
      'JSON::XS' => 0,
      'Text::ParseWords' => 0,
      'Storable' => 0,
      'Carp' => 0,
      'Data::Dumper' => 0,
      'File::Slurp' => 0,
      'File::Temp' => 0,
      'Net::IPv4Addr' => 0,
      'Regexp::IPv4' => 0,
      'Regexp::IPv6' => 0,
      'Text::CSV_XS' => 0,
   },
   configure_requires => {
      'Module::Build' => 0,
   },
   script_files => [ qw(bin/onyphe bin/opp) ],
);

$builder->create_build_script;
