#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Merge;
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
         run => [ qw(page state argument) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $argument) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $argument) or return;

   my $cb = sub {
      my ($this, $state, $new, $argument) = @_;

      # Update where clause with placeholder values
      my $copy = $argument;
      while ($copy =~
         s{([\w\.]+)\s*:\s*\$([\w\.]+)}{$1:@{[$self->value($this, $2)]}}) {
         #$self->log->debug("1[$1] 2[$2] value[".$self->value($this, $2)."]");
      }
      my $this_r = $self->search($copy, 1, 1) or return;
      if ($this_r->{count} > 0) {  # Check only first page of results.
         # Merge only first result from first page.
         my %new = ( %$this, %{$this_r->{results}[0]} );
         push @$new, \%new;
      }

      return 1;
   };

   return $self->iter($page, $cb, $state, $argument);
}

1;
