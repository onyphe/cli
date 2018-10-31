#
# $Id: Makefile.PL,v 635de629083a 2018/10/30 17:14:02 gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Metabrik::Client::Onyphe',
   MIN_PERL_VERSION => '5.6.1',
   VERSION_FROM => 'lib/Metabrik/Client/Onyphe.pm',
   LICENSE => 'bsd',
   ABSTRACT_FROM => 'lib/Metabrik/Client/Onyphe.pm',
   AUTHOR => 'ONYPHE <contact_at_onyphe.io>',
   PREREQ_PM => {
      'Metabrik' => '1.31',
      'Metabrik::Repository' => '1.31',
   },
   EXE_FILES => [ qw(bin/onyphe) ],
);
