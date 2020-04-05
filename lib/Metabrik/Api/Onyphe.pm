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
      },
      attributes_default => {
         apiurl => 'https://www.onyphe.io/api/v2',
         wait => 3,
      },
      commands => {
        api => [ qw(api ip apikey|OPTIONAL page|OPTIONAL) ],
        ip => [ qw(ip apikey|OPTIONAL) ],
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
        add => [ qw(string apikey|OPTIONAL page|OPTIONAL) ],
        del => [ qw(string apikey|OPTIONAL page|OPTIONAL) ],
        search_datascan => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_inetnum => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_pastries => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_resolver => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_synscan => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_threatlist => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_onionscan => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_sniffer => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_ctl => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_datashot => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_onionshot => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        user => [ qw(apikey|OPTIONAL) ],
      },
   };
}

sub api {
   my $self = shift;
   my ($api, $arg, $apikey, $page) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('api', $api) or return;
   $self->brik_help_run_undef_arg('api', $arg) or return;
   my $ref = $self->brik_help_run_invalid_arg('api', $arg, 'SCALAR', 'ARRAY') or return;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;

   my $wait = $self->wait;

   $api =~ s{_}{/}g;

   my $apiurl = $self->apiurl;
   $apiurl =~ s{/*$}{};

   $self->log->verbose("api: using url[$apiurl]");

   my @r = ();
   if ($ref eq 'ARRAY') {
      for my $this (@$arg) {
         my $res = $self->api($api, $this, $apikey, $page) or next;
         push @r, @$res;
      }
   }
   else {
   RETRY:
      my $url;
      $url = $apiurl.'/'.$api.'/'.$arg unless $api eq "alert/list" or $api eq "alert/add";
      $url = $apiurl.'/'.$api if $api eq "alert/list" or $api eq "alert/add";
      if (defined($page)) {
         $url .= '?page='.$page;
      }

      $self->add_headers({"Authorization" => "apikey $apikey"}) unless $api eq "alert/add";
      $self->add_headers({"Authorization" => "apikey $apikey", "Content-Type" => "application/json"}) if $api eq "alert/add";
      my $res;
      $res = $self->get($url) unless $api eq "alert/add" or $api eq "alert/del";
      $res = $self->post($arg, $url) if $api eq "alert/add";
      $res = $self->post("", $url) if $api eq "alert/del";
      my $code = $self->code;
      if ($code == 429) {
         $self->log->verbose("api: request limit reached, waiting before retry");
         sleep($wait);
         goto RETRY;
      }
      elsif ($code == 200) {
         my $content = $self->content;
         if ($content->{status} eq 'nok') {
            my $message = $content->{message};
            return $self->log->error("api: got error with message [$message]");
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

sub ip {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('summary/ip', $ip, $apikey, $page);
}

sub domain {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('summary/domain', $ip, $apikey, $page);
}

sub hostname {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;
 
   return $self->api('summary/hostname', $ip, $apikey, $page);
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

sub list {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('alert/list', "", $apikey, $page);
}

sub add {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('alert/add', $query, $apikey, $page);
}

sub del {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('alert/del', $query, $apikey, $page);
}

sub search_datascan {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_datascan', $query, $apikey, $page);
}

sub search_inetnum {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_inetnum', $query, $apikey, $page);
}

sub search_pastries {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_pastries', $query, $apikey, $page);
}

sub search_resolver {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_resolver', $query, $apikey, $page);
}

sub search_synscan {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_synscan', $query, $apikey, $page);
}

sub search_threatlist {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_threatlist', $query, $apikey, $page);
}

sub search_onionscan {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_onionscan', $query, $apikey, $page);
}

sub search_sniffer {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_sniffer', $query, $apikey, $page);
}

sub search_ctl {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_ctl', $query, $apikey, $page);
}

sub search_datashot {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_datashot', $query, $apikey, $page);
}

sub search_onionshot {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_onionshot', $query, $apikey, $page);
}

sub user {
   my $self = shift;
   my ($apikey) = @_;

   return $self->api('user', '', $apikey);
}

1;

__END__

=head1 NAME

Metabrik::Api::Onyphe - api::onyphe Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
