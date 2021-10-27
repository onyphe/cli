#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Fields;
use strict;
use warnings;

use base qw(Metabrik::Client::Onyphe::Function);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(client onyphe) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         run => [ qw(page state args) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $args) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $args) or return;

   my $arg = $self->parse($args);
   my $keep = $arg->[0] || {};

   if (defined($keep)) {
      $keep = { map { $_ => 1 } split(/\s*,\s*/, $keep) };
   }

   my $cb = sub {
      my ($this, $state, $new, $keep) = @_;

      for my $k (keys %$this) {
         next if $keep->{$k};
         delete $this->{$k};
      }

      push @$new, $this;

      return 1;
   };

   return $self->iter($page, $cb, $state, $keep);
}

1;
