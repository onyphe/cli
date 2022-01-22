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
         process => [ qw(flat state args output) ],
      },
   };
}

#
# | fields ip,protocol,domain,app.http.component.product
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $parsed = $self->parse_v2($args);
   my $keep = $parsed->{0} || {};

   # Build list of fields to be kept from input argument:
   if (defined($keep)) {
      $keep = { map { $_ => 1 } split(/\s*,\s*/, $keep) };
   }

   # Get list of full flat field names:
   my $fields = $self->fields($flat);

   # Iterate over all flat fields and delete those not wanted for being kept:
   for my $k (@$fields) {
      $self->delete($flat, $k) if !$keep->{$k};
   }

   push @$output, $flat;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Fields - client::onyphe::function::fields Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
