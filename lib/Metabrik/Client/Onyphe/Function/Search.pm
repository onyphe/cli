#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Search;
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
         run => [ qw(results search) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($r, $search) = @_;

   $self->brik_help_run_undef_arg('run', $r) or return;
   $self->brik_help_run_invalid_arg('run', $r, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('run', $search) or return;

   my @new = ();

   my $return = sub {
      return [ {
         %{$r->[0]},            # Keep results information from first page only
         count => scalar(@new), # Overwrite count value
         results => \@new,      # Overwrite results value
      } ];
   };

   my $last = 0;
   $SIG{INT} = sub {
      $last = 1;
      return $return->();
   };

   for my $page (@$r) {
      for my $this (@{$page->{results}}) {
         # Update search clause with placeholder values
         my $copy = $search;
         while ($copy =~
            s{([\w\.]+)\s*:\s*\$([\w\.]+)}{$1:@{[$self->_value($this, $2)]}}) {
         }
         my $this_r = $self->search($copy, 1, 1) or return;
         if ($this_r->[0]{count} > 0) {  # Check only first page of results.
            push @new, @{$this_r->[0]{results}}; # Keep these results if matche
s were found.
         }
      }
   }

   return $return->();
}

1;
