#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Where;
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
         run => [ qw(results where state|OPTIONAL) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($r, $where) = @_;

   $self->brik_help_run_undef_arg('run', $r) or return;
   $self->brik_help_run_invalid_arg('run', $r, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('run', $where) or return;

   my @new = ();

   my $last = 0;
   $SIG{INT} = sub {
      $last = 1;
      return $self->return($r, \@new);
   };

   for my $page (@$r) {
      for my $this (@{$page->{results}}) {
         # Update where clause with placeholder values
         my $copy = $where;
         while ($copy =~
            s{([\w\.]+)\s*:\s*\$([\w\.]+)}{$1:@{[$self->value($this, $2)]}}) {
            #$self->log->debug("1[$1] 2[$2] value[".$self->value($this, $2)."]");
         }
         my $this_r = $self->search($copy, 1, 1) or return;
         if ($this_r->[0]{count} > 0) {  # Check only first page of results.
            push @new, $this;            # Keep this result if matches were found.
         }
         last if $last;
      }
      last if $last;
   }

   return $self->return($r, \@new);
}

1;
