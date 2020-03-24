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
         run => [ qw(page state) ],
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

sub run {
   my $self = shift;
   my ($page, $state) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;

   my $cb = sub {
      my ($this, $state, $new) = @_;

      my $ip = $this->{ip};
      my $port = $this->{port};
      my $forward = $this->{forward} || '';
      my $tls = $this->{tls};
      my $path = $this->{url} || '/';

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
      my $output = "/tmp/http-shot-$copy.jpg";

      my $cmd = "timeout --kill-after=20s --signal=QUIT 15s cutycapt --insecure --delay=5000 --max-wait=10000 --private-browsing=on --java=off --javascript=on --url=$url --out=$output --min-width=1024 --min-height=768";

      $self->log->verbose("url[$url]");
      $self->log->verbose("output[$output]");
      $self->log->verbose("cmd[$cmd]");

      $self->log->info("taking screenshot for [$url], output [$output]");

      system("$cmd 2> /dev/null &");

      return 1;
   };

   return $self->iter($page, $cb, $state);
}

1;
