#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Expand;
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

#
# When a document has an ARRAY of domains into domain field, we want
# to create as many documents as the number of domains with same
# values for other fields:
#
# NOTE: currently can only expand on 1 field.
#
# | expand domain
#
sub run {
   my $self = shift;
   my ($page, $state, $args) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $args) or return;

   my $arg = $self->parse($args);
   my $field = $arg->[0];

   $self->brik_help_run_undef_arg('run', $field) or return;

   my $cb = sub {
      my ($this, $state, $new, $field) = @_;

      my $value = $self->value_as_array($this, $field) or return 1;

      for my $v (@$value) {
         my $copy = $self->clone($this);
         $copy->{$field} = [ $v ];
         push @$new, $copy;
      }

      return 1;
   };

   return $self->iter($page, $cb, $state, $field);
}

1;
