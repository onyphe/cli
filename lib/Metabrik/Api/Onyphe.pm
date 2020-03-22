#
# $Id: Onyphe.pm,v 31687a060e97 2019/03/04 12:41:04 gomor $
#
# api::onyphe Brik
#
package Metabrik::Api::Onyphe;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision: 31687a060e97 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         apikey => [ qw(key) ],
         apiurl => [ qw(url) ],
         wait => [ qw(seconds) ],
         master => [ qw(0|1) ],
      },
      attributes_default => {
         apiurl => 'https://www.onyphe.io/api/v2',
         wait => 1,
         master => 0,
      },
      commands => {
        api => [ qw(api ip apikey|OPTIONAL page|OPTIONAL) ],
        summary_ip => [ qw(ip apikey|OPTIONAL) ],
        summary_domain => [ qw(ip apikey|OPTIONAL) ],
        summary_hostname => [ qw(ip apikey|OPTIONAL) ],
        geoloc => [ qw(ip) ],
        pastries => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        inetnum => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        threatlist => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        topsite => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        synscan => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        vulnscan => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        datascan => [ qw(ip|string apikey|OPTIONAL page|OPTIONAL) ],
        onionscan => [ qw(ip|string apikey|OPTIONAL page|OPTIONAL) ],
        sniffer => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        ctl => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        reverse => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        forward => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        onionshot => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        datashot => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        datamd5 => [ qw(sum apikey|OPTIONAL) ],
        domain => [ qw(string apikey|OPTIONAL page|OPTIONAL) ],
        hostname => [ qw(string apikey|OPTIONAL page|OPTIONAL) ],
        list => [ qw(apikey|OPTIONAL page|OPTIONAL) ],
        search => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        user => [ qw(apikey|OPTIONAL) ],
        export => [ qw(query callback apikey|OPTIONAL) ],
      },
      require_modules => {
         'AnyEvent' => [ ],
         'AnyEvent::HTTP' => [ ],
         'URI::Escape' => [ ],
      },
   };
}

sub api {
   my $self = shift;
   my ($api, $arg, $apikey, $page) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('api', $api) or return;
   $self->brik_help_run_undef_arg('api', $arg) or return;
   my $ref = $self->brik_help_run_invalid_arg('api', $arg, 'SCALAR', 'ARRAY')
      or return;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;

   my $wait = $self->wait;

   $api =~ s{_}{/}g;

   my $apiurl = $self->apiurl;
   $self->add_headers({
      'Authorization' => "apikey $apikey",
      'Content-Type' => 'application/json',
   });

   $self->log->verbose("api: using url[$apiurl]");

   my @r = ();
   if ($ref eq 'ARRAY') {
      for my $this (@$arg) {
         $this = URI::Escape::uri_escape_utf8($this);
         my $res = $self->api($api, $this, $apikey, $page) or next;
         push @r, @$res;
      }
   }
   else {
      $arg = URI::Escape::uri_escape_utf8($arg);
   RETRY:
      my $url = $apiurl.'/'.$api.'/'.$arg;
      if (defined($page)) {
         $url .= '?page='.$page;
      }

      my $res = $self->get($url);
      my $code = $self->code;
      if ($code == 429) {
         $self->log->verbose("api: request limit reached, waiting before retry");
         if (defined($wait) && $wait > 0) {
            sleep($wait);
         }
         goto RETRY;
      }
      elsif ($code == 200) {
         my $content = $self->content;
         if ($content->{status} eq 'nok') {
            my $text = $content->{text};
            return $self->log->error("api: got error with text [$text]");
         }
         else {
            $content->{arg} = $arg;  # Add the IP or other info,
                                     # in case an ARRAY was requested.
            push @r, $content;
         }
      }
      else {
         return $self->log->error("api: error code [$code] for api [$api] query [$arg]");
      }
   }

   return \@r;
}

sub geoloc {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/geoloc', $ip, $apikey, $page);
}

sub summary_ip {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('summary/ip', $ip, $apikey);
}

sub summary_domain {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('summary/domain', $ip, $apikey);
}

sub summary_hostname {
   my $self = shift;
   my ($ip, $apikey) = @_;
 
   return $self->api('summary/hostname', $ip, $apikey);
}

sub pastries {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/pastries', $ip, $apikey, $page);
}

sub inetnum {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/inetnum', $ip, $apikey, $page);
}

sub threatlist {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/threatlist', $ip, $apikey, $page);
}

sub topsite {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/topsite', $ip, $apikey, $page);
}

sub synscan {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/synscan', $ip, $apikey, $page);
}

sub vulnscan {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/vulnscan', $ip, $apikey, $page);
}

sub datascan {
   my $self = shift;
   my ($ip_or_string, $apikey, $page) = @_;

   return $self->api('simple/datascan', $ip_or_string, $apikey, $page);
}

sub onionscan {
   my $self = shift;
   my ($onion, $apikey, $page) = @_;

   return $self->api('simple/onionscan', $onion, $apikey, $page);
}

sub sniffer {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/sniffer', $ip, $apikey, $page);
}

sub ctl {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/ctl', $ip, $apikey, $page);
}

sub reverse {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/resolver/reverse', $ip, $apikey, $page);
}

sub forward {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/resolver/forward', $ip, $apikey, $page);
}

sub onionshot {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/onionshot', $ip, $apikey, $page);
}

sub datashot {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/datashot', $ip, $apikey, $page);
}

sub datamd5 {
   my $self = shift;
   my ($sum, $apikey, $page) = @_;

   return $self->api('simple/datascan/datamd5', $sum, $apikey, $page);
}

sub search {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search', $query, $apikey, $page);
}

sub user {
   my $self = shift;
   my ($apikey) = @_;

   return $self->api('user', '', $apikey);
}

sub export {
   my $self = shift;
   my ($query, $callback, $apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('export', $query) or return;
   $self->brik_help_run_undef_arg('export', $callback) or return;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;

   my $apiurl = $self->apiurl;
   $query = URI::Escape::uri_escape_utf8($query);

   $self->log->verbose("export: using url[$apiurl]");

   my $api = '/export/';
   if ($self->master) {
      $api = '/master/export/';
   }
   my $url = $apiurl.$api.$query;

   $self->add_headers({
      'Authorization' => "apikey $apikey",
      'Content-Type' => 'application/json',
   });

   # Will store incomplete line for later processing
   my $buf = '';

   # To keep state between each page of results
   my $state = {};

   my $cv = AnyEvent->condvar;

   AnyEvent::HTTP::http_get($url,
      headers => {
         'Authorization' => "apikey $apikey",
         'Content-Type' => "application/json",
      },
      on_body => sub {
         my ($data, $hdr) = @_;

         $data = $buf.$data;  # Complete from previous remaining buf

         my $status = $hdr->{Status};
         my $encoding = $hdr->{'transfer-encoding'};
         if ($status == 200 && $encoding eq 'chunked') {
            # $this will contain all lines until the last one
            # with \n ending chars. This last one will be put back
            # into $buf for next processing.
            # Thus, we only handle input stream on a line-by-line basis.
            my ($this, $tail) = $data =~ m{^(.*?\n)([^\n]*)$}s;
            # One line is not complete, add to buf and go to next:
            if (!defined($this)) {
               $buf = $data;
               return 1;
            }

            my @lines = split(/\n/, $this);
            $buf = $tail || '';

            $callback->(\@lines, $state);
         }
         else {
            print STDERR "ERROR: status [$status]\n";
            print $data."\n";
            return $cv->send;
         }
 
         return 1;
      },
      # Completion callback
      sub {
         my (undef, $hdr) = @_;
 
         my $status = $hdr->{Status};
         #print STDERR "status [$status]\n";

         return $cv->send;
      },
   );

   # Wait for termination
   return $cv->recv;
}

1;

__END__

=head1 NAME

Metabrik::Api::Onyphe - api::onyphe Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
