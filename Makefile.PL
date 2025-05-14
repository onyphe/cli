#
# $Id: Makefile.PL,v 604fb44b35f9 2025/03/27 09:23:31 gomor $
#
use strict;
use warnings;

use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Onyphe',
   MIN_PERL_VERSION => '5.6.1',
   VERSION_FROM => 'lib/Onyphe.pm',
   LICENSE => 'bsd',
   ABSTRACT_FROM => 'lib/Onyphe.pm',
   AUTHOR => 'ONYPHE <contact_at_onyphe.io>',
   PREREQ_PM => {
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
   EXE_FILES => [ qw(bin/onyphe bin/opp) ],
);
