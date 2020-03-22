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
         return => [ qw(results new) ],
      },
   };
}

sub value {
   my $self = shift;
   my ($h, $field) = @_;

   $self->brik_help_run_undef_arg('value', $h) or return;
   $self->brik_help_run_undef_arg('value', $field) or return;

   my @words = split(/\./, $field);
   # Iterate over objects elements:
   my $value = $h->{$words[0]};
   for (1..$#words) {
      $value = $value->{$words[$_]};
   }

   if (! defined($value)) {
      return $self->log->error("value: no value found for field [$field]");
   }

   return $value;
}

sub return {
   my $self = shift;
   my ($r, $new) = @_;

   $self->brik_help_run_undef_arg('return', $new) or return;
   $self->brik_help_run_invalid_arg('return', $new, 'ARRAY') or return;

   return [ {
      %{$r->[0]},             # Keep results information from first page only
      count => scalar(@$new), # Overwrite count value
      results => $new,        # Overwrite results value
   } ];
}

1;
