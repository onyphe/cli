#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Merge;
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
# | merge category:vulnscan ip:$ip
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   # Keep original results:
   push @$output, $flat;

   my $ao_cb = sub {
      my ($results) = @_;
      if (defined($results->{count}) && $results->{count} > 0) {
         # Merge new results:
         #$self->log->info("merging");
         my $flats = $self->flatten($results->{results});
         #print Data::Dumper::Dumper($flats)."\n";
         #push @$output, @{$self->flatten($results->{results})};
         push @$output, @$flats;
      }
   };

   # Update place holders with found input values:
   my $merges = $self->placeholder($args, $flat);

   for my $merge (@$merges) {
      $self->log->verbose("merge[$merge]");
      $self->ao->search($merge, [ { page => 1 } ], $ao_cb);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Merge - client::onyphe::function::merge Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
