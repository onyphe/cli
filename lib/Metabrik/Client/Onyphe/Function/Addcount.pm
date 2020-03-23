#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Addcount;
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
         run => [ qw(results undef state|OPTIONAL) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($r, undef, $state) = @_;

   $self->brik_help_run_undef_arg('run', $r) or return;
   $self->brik_help_run_invalid_arg('run', $r, 'ARRAY') or return;

   my $count = $state->{count}{count} || 0;

   my @new = ();
   for my $page (@$r) {
      my $count = $page->{count};
      for my $this (@{$page->{results}}) {
         $state->{count}{count}++;
         $this->{count} = $state->{count}{count};
         push @new, $this;
      }
   }

   return $self->return($r, \@new, $state);
}

1;
