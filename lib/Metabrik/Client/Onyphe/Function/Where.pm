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
      tags => [ qw(client onyphe) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         process => [ qw(flat state args output) ],
      },
   };
}

sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $ao_cb = sub {
      my ($results) = @_;
      if (defined($results->{count}) && $results->{count} > 0) {
         # Keep original result if matches were found:
         push @$output, $flat;
      }
   };

   # Update place holders with found input values:
   my $searches = $self->placeholder($args, $flat);

   for my $search (@$searches) {
      $self->log->verbose("where[$search]");
      $self->ao->search($search, [ { page => 1 } ], $ao_cb);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Where - client::onyphe::function::where Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
