#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Httpshot;
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
         'cutycapt' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(cutycapt) ],
         debian => [ qw(cutycapt) ],
         kali => [ qw(cutycapt) ],
      },
   };
}

#
# | httpshot
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   my $ip = $flat->{ip};
   my $port = $flat->{port};
   my $forward = $flat->{forward} || '';
   my $tls = $flat->{tls};
   my $path = $flat->{url} || '/';

   my $url = ($tls && $tls eq 'true') ? 'https' : 'http';
   if (length($forward)) {
      $url .= "://$forward";
   }
   else {
      $url .= "://$ip";
   }
   $url .= ":$port".$path;

   my $copy = $url;
   $copy =~ s{[:/]}{_}g;
   my $jpg = "/tmp/http-shot-$copy.jpg";

   my $cmd = "timeout --kill-after=20s --signal=QUIT 15s cutycapt --insecure --delay=5000 --max-wait=10000 --private-browsing=on --java=off --javascript=on --url=$url --out=$jpg --min-width=1024 --min-height=768";

   $self->log->verbose("url[$url]");
   $self->log->verbose("jpg[$jpg]");
   $self->log->verbose("cmd[$cmd]");

   $self->log->info("taking screenshot for [$url], output [$jpg]");

   system("$cmd 2> /dev/null &");

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Httpshot - client::onyphe::function::httpshot Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
