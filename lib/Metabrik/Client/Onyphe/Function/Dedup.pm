#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Dedup;
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
         run => [ qw(results field) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($r, $field) = @_;

   $self->brik_help_run_undef_arg('run', $r) or return;
   $self->brik_help_run_invalid_arg('run', $r, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('run', $field) or return;

   my %dedup = ();
   my @new = ();
   for my $page (@$r) {
      for my $this (@{$page->{results}}) {
         my $value = $self->_value($this, $field) or next;
         $value = ref($value) eq 'ARRAY' ? $value : [ $value ];
         # Results are ordered in latest time first, thus we keep the freshest result.
         my $new = 0;
         for my $v (@$value) {
            if (! exists($dedup{$v})) {
               $dedup{$v}++;
               $new = 1;
            }
         }
         if ($new) {
            push @new, $this;
         }
      }
   }

   # Return new result set.
   return [ {
      %{$r->[0]},            # Keep results information from first page only
      count => scalar(@new), # Overwrite count value
      results => \@new,      # Overwrite results value
   } ];
}

1;
