#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Whois;
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
         'Metabrik::Shell::Command' => [ ],
      },
      require_binaries => {
         'whois' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(whois) ],
         debian => [ qw(whois) ],
         kali => [ qw(whois) ],
      },
   };
}

#
# | whois
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   my $ip = $flat->{ip};
   return 1 unless defined($ip);

   my $domains = $self->value($flat, 'domain');
   return 1 unless defined($domains);

   for my $domain (@$domains) {
      my $target = $domain || $ip;
      next if $state->{whois}{$domain};

      $state->{whois}{$target}++;

      my $output = "/tmp/$target.whois";

      my $cmd = "timeout --kill-after=20s --signal=QUIT 15s whois $target";

      $self->log->verbose("output[$output]");
      $self->log->verbose("cmd[$cmd]");

      $self->log->info("launching whois for [$target], output [$output]");

      system("$cmd > $output 2> /dev/null &");
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Whois - client::onyphe::function::whois Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
