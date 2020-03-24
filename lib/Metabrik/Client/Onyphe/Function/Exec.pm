#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Exec;
use strict;
use warnings;

use base qw(Metabrik::Client::Onyphe::Function);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(unstable) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         run => [ qw(page state command) ],
      },
      require_modules => {
         'Metabrik::File::Json' => [ ],
         'Metabrik::String::Random' => [ ],
         'Metabrik::Shell::Command' => [ ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $command) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $command) or return;

   my $jf = Metabrik::File::Json->new_from_brik_init($self) or return;
   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;
   my $sr = Metabrik::String::Random->new_from_brik_init($self) or return;

   my $cb = sub {
      my ($this, $state, $new, $command) = @_;

      my $file = $sr->filename;
      $jf->write($this, $file) or return;
      $sc->execute($command, $file) or return;

      return 1;
   };

   return $self->iter($page, $cb, $state, $command);
}

1;
