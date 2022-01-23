#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Export;
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
# NOTE: currently doesn't work because we cannot call 2 times api_streaming().
#
# | export category:vulnscan ip:$ip
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $ao_cb = sub {
      my ($results) = @_;
      if (defined($results->{count}) && $results->{count} > 0) {
         # Keep this page results if matches were found.
         my @flats = ();
         push @flats, $self->flatten($_) for (@{$results->{results}});
         push @$output, @flats;
      }
   };

   # Update place holders with found input values:
   my $exports = $self->placeholder($args, $flat);

   for my $export (@$exports) {
      $self->log->verbose("export[$export]");
      $self->ao->export($export, undef, $ao_cb);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Export - client::onyphe::function::export Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
