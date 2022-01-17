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
         run => [ qw(page state) ],
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
sub run {
   my $self = shift;
   my ($page, $state) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;

   my $cb = sub {
      my ($this, $state, $new, $field) = @_;

      my $value = $self->value_as_array($this, $field) or return 1;

      for my $v (@$value) {
         #$self->log->info("splitting subnet[$v]");
         my ($subnet, $cidr) = $v =~ m{^([^/]+)/(\d+)$};

         if ($na->is_ipv4($subnet)) {
            # Don't touch anything if CIDR is at least /16:
            if ($cidr >= 16) {
               my $copy = $self->clone($this);
               $copy->{$field} = $v;  # subnet is never an ARRAY
               #$self->log->info("old subnet[$v]");
               push @$new, $copy;
            }
            # If not, split into other subnets:
            else {
               if ($na->is_ipv4($subnet)) {
                  my $count = $na->count_ipv4($subnet.'/'.$cidr);
                  my $chunks = $count / 65536;  # Chunk by X number of /16
                  my $this_subnet = $subnet.'/16';
                  for (1..$chunks) {
                     my $copy = $self->clone($this);
                     $copy->{$field} = $this_subnet;  # subnet is never an ARRAY
                     #$self->log->info("new subnet[$this_subnet]");
                     push @$new, $copy;
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
            push @$new, $this;
         }
      }

      return 1;
   };

   return $self->iter($page, $cb, $state, 'subnet');
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
