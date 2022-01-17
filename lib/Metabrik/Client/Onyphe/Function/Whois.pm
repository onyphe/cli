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
         run => [ qw(page state) ],
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

sub run {
   my $self = shift;
   my ($page, $state) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   my $cb = sub {
      my ($this, $state, $new) = @_;

      my $ip = $this->{ip};
      my $domain = $self->value_as_array($this, 'domain');
      for my $this_domain (@$domain) {
         my $target = $this_domain || $ip;
         next if $state->{whois}{$this_domain};

         $state->{whois}{$target}++;

         my $output = "/tmp/$target.whois";

         my $cmd = "timeout --kill-after=20s --signal=QUIT 15s whois $target";

         $self->log->verbose("output[$output]");
         $self->log->verbose("cmd[$cmd]");

         $self->log->info("launching whois for [$target], output [$output]");

         system("$cmd > $output 2> /dev/null &");
      }

      return 1;
   };

   return $self->iter($page, $cb, $state);
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
