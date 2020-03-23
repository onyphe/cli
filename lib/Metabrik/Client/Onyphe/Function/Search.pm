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
         run => [ qw(page state search) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $search) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $search) or return;

   my $cb = sub {
      my ($this, $state, $new, $search) = @_;

      # Update search clause with placeholder values
      my $copy = $search;
      while ($copy =~
         s{([\w\.]+)\s*:\s*\$([\w\.]+)}{$1:@{[$self->value($this, $2)]}}) {
      }
      my $this_page = $self->search($copy, 1, 1) or return;
      if ($this_page->{count} > 0) {  # Check only first page of results.
         push @$new, @{$this_page->{results}}; # Keep this page if matches were found.
      }

      return 1;
   };

   return $self->iter($page, $cb, $state, $search);
}

1;
