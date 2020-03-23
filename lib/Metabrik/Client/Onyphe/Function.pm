#
# $Id$
#
package Metabrik::Client::Onyphe::Function;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(unstable) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         value => [ qw(doc field) ],
         value_as_array => [ qw(doc field) ],
         iter => [ qw(page callback) ],
         return => [ qw(page new state|OPTIONAL) ],
      },
   };
}

sub value {
   my $self = shift;
   my ($doc, $field) = @_;

   $self->brik_help_run_undef_arg('value', $doc) or return;
   $self->brik_help_run_undef_arg('value', $field) or return;

   my @words = split(/\./, $field);
   # Iterate over objects elements:
   my $value = $doc->{$words[0]};
   for (1..$#words) {
      $value = $value->{$words[$_]};
   }

   return $value;
}

sub value_as_array {
   my $self = shift;
   my ($doc, $field) = @_;

   $self->brik_help_run_undef_arg('value_as_array', $doc) or return;
   $self->brik_help_run_undef_arg('value_as_array', $field) or return;

   my $value = $self->value($doc, $field) or return;
   $value = ref($value) eq 'ARRAY' ? $value : [ $value ];

   return $value;
}

sub iter {
   my $self = shift;
   my ($page, $cb, $state, @args) = @_;

   my @new = ();

   for my $this (@{$page->{results}}) {
      # If callback returns undef, we consider it a fatal error, we abort.
      $cb->($this, $state, \@new, @args) or return;
   }

   return $self->return($page, \@new);
}

sub return {
   my $self = shift;
   my ($page, $new, $state) = @_;

   $self->brik_help_run_undef_arg('return', $new) or return;
   $self->brik_help_run_invalid_arg('return', $new, 'ARRAY') or return;

   return {
      %$page,                 # Get defaults results, then overwrite some
      count => scalar(@$new), # Overwrite count value
      results => $new,        # Overwrite results value
      state => $state,
   };
}

1;
