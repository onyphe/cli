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
         process => [ qw(flat state args output) ],
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
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $parsed = $self->parse($args);
   my $field = $parsed->{0};

   my $values = $self->value($flat, $field);
   return 1 unless defined($values);

   for my $v (@$values) {
      my $copy = $self->clone($flat);
      $copy->{$field} = $v;
      push @$output, $copy;
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Expand - client::onyphe::function::expand Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
