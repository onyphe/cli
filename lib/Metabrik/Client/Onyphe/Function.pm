#
# $Id$
#
package Metabrik::Client::Onyphe::Function;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(unstable) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         return => [ qw(new) ],
      },
   };
}

sub return {
   my $self = shift;
   my ($new) = @_;

   $self->brik_help_run_undef_arg('return', $new) or return;
   $self->brik_help_run_invalid_arg('run', $new, 'ARRAY') or return;

   return [ {
      count => scalar(@$new), # Overwrite count value
      results => $new,        # Overwrite results value
   } ];
}

1;
