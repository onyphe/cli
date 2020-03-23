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
         run => [ qw(page state where) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $where) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $where) or return;

   my $cb = sub {
      my ($this, $state, $new, $where) = @_;

      # Update where clause with placeholder values
      my $copy = $where;
      while ($copy =~
         s{([\w\.]+)\s*:\s*\$([\w\.]+)}{$1:@{[$self->value($this, $2)]}}) {
         #$self->log->debug("1[$1] 2[$2] value[".$self->value($this, $2)."]");
      }
      my $this_page = $self->search($copy, 1, 1) or return;
      if ($this_page->{count} > 0) {
         push @$new, $this;           # Keep this page if matches were found.
      }

      return 1;
   };

   return $self->iter($page, $cb, $state, $where);
}

1;
