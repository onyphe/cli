#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Uniq;
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
         run => [ qw(page state field) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $field) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $field) or return;

   my $cb = sub {
      my ($this, $state, $new, $field) = @_;

      my $value = $self->value_as_array($this, $field) or return 1;

      my @new = @$new;
      for my $v (@$value) {
         next if $state->{uniq}{$v};
         $state->{uniq}{$v}++;
         push @new, { $field => $v };
      }
      @$new = @new;

      return 1;
   };

   return $self->iter($page, $cb, $state, $field);
}

1;
