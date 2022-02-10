#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Splitsubnet;
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
      require_modules => {
         'Metabrik::Network::Address' => [ ],
      },
   };
}

#
# Takes a subnet field greater than /16 and make multiple smaller subnets
# so we can query ONYPHE API. By default, subnets larger than /16 are not
# queryable. /16 or greater subnets will be taken with no change.
#
# | splitsubnet
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;

   my $parsed = $self->parse_v2($args);
   my $field = $parsed->{0} || 'subnet';

   my $values = $self->value($flat, $field);
   return 1 unless defined($values);

   for my $v (@$values) {
      my ($subnet, $cidr) = $v =~ m{^([^/]+)/(\d+)$};

      if ($na->is_ipv4($subnet)) {
         # Don't touch anything if CIDR is at least /16:
         if ($cidr >= 16) {
            my $copy = $self->clone($flat);
            $copy->{$field} = $v;  # subnet is never an ARRAY
            #$self->log->info("old subnet[$v]");
            push @$output, $copy;
         }
         # If not, split into other subnets:
         else {
            if ($na->is_ipv4($subnet)) {
               my $count = $na->count_ipv4($subnet.'/'.$cidr);
               my $chunks = $count / 65536;  # Chunk by X number of /16
               my $this_subnet = $subnet.'/16';
               for (1..$chunks) {
                  my $copy = $self->clone($flat);
                  $copy->{$field} = $this_subnet;  # subnet is never an ARRAY
                  #$self->log->info("new subnet[$this_subnet]");
                  push @$output, $copy;
                  # Prepare for next round:
                  my $last = $na->ipv4_last_address($this_subnet);
                  my $last_int = $na->ipv4_to_integer($last) + 1;
                  $this_subnet = $na->integer_to_ipv4($last_int).'/16';
               }
            }
         }
      }
      # IPv6 not handled yet, simply returns original object:
      else {
         push @$output, $flat;
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Splitsubnet - client::onyphe::function::splitsubnet Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
