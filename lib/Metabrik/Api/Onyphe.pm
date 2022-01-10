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
      tags => [ qw(client onyphe) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         apikey => [ qw(key) ],
         apiurl => [ qw(url) ],
         apiargs => [ qw(args) ],
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
        bulk => [ qw(api input callback apikey|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Json' => [ ],
         'Metabrik::File::Text' => [ ],
         'AnyEvent' => [ ],
         'AnyEvent::HTTP' => [ ],
         'URI::Escape' => [ ],
      },
   };
}

sub api {
   my $self = shift;
   my ($api, $arg, $apikey, $currentpage, $callback) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('api', $api) or return;
   $self->brik_help_run_undef_arg('api', $arg) or return;

   my $wait = $self->wait;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my $apiurl = $self->apiurl;
   my $apiargs = $self->apiargs;
   $self->add_headers({
      'Authorization' => "apikey $apikey",
      'Content-Type' => 'application/json',
   });

   $self->log->verbose("api: using url[$apiurl]");

   $arg = URI::Escape::uri_escape_utf8($arg);
   $self->log->debug("api: uri_escape_utf8 arg[$arg]");

   # Default callback does nothing:
   $callback ||= sub {
      my ($page) = @_;

      return $page;
   };

   my $url = $apiurl.'/'.$api.'/'.$arg;
   if (defined($apiargs)) {
      $url .= $apiargs;
   }
   if (defined($currentpage)) {
      if (!defined($apiargs)) {
         $url .= '?page='.$currentpage;
      }
      else {
         $url .= '&page='.$currentpage;
      }
   }

   my $abort = 0;
   $SIG{INT} = sub {
      $abort++;
   };

   my $page;

   RETRY:

   my $res = $self->get($url);
   my $code = $self->code;
   if ($code == 429) {
      $self->log->warning("api: request limit reached, waiting before retry");
      if (defined($wait) && $wait > 0) {
         sleep($wait);
      }
      goto RETRY;
   }
   elsif ($code == 400) {
      $page = $self->content;
      $self->log->error("api: bad request: ".$page->{text});
   }
   elsif ($code == 200) {
      $page = $self->content;
   }
   else {
      $self->log->error("api: code [$code], waiting before retry");
      if (defined($wait) && $wait > 0) {
         sleep($wait);
      }
      goto RETRY;
   }

   if ($abort) {
      return;
   }

   return $callback->($page);
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

sub simple_geoloc {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/geoloc', $ip, $apikey, $page);
}

sub simple_pastries {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/pastries', $ip, $apikey, $page);
}

sub simple_inetnum {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/inetnum', $ip, $apikey, $page);
}

sub simple_threatlist {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/threatlist', $ip, $apikey, $page);
}

sub simple_topsite {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/topsite', $ip, $apikey, $page);
}

sub simple_synscan {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/synscan', $ip, $apikey, $page);
}

sub simple_vulnscan {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/vulnscan', $ip, $apikey, $page);
}

sub simple_datascan {
   my $self = shift;
   my ($ip_or_string, $apikey, $page) = @_;

   return $self->api('simple/datascan', $ip_or_string, $apikey, $page);
}

sub simple_onionscan {
   my $self = shift;
   my ($onion, $apikey, $page) = @_;

   return $self->api('simple/onionscan', $onion, $apikey, $page);
}

sub simple_sniffer {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/sniffer', $ip, $apikey, $page);
}

sub simple_ctl {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/ctl', $ip, $apikey, $page);
}

sub simple_resolver_reverse {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/resolver/reverse', $ip, $apikey, $page);
}

sub simple_resolver_forward {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/resolver/forward', $ip, $apikey, $page);
}

sub simple_onionshot {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/onionshot', $ip, $apikey, $page);
}

sub simple_datashot {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('simple/datashot', $ip, $apikey, $page);
}

sub simple_datascan_datamd5 {
   my $self = shift;
   my ($sum, $apikey, $page) = @_;

   return $self->api('simple/datascan/datamd5', $sum, $apikey, $page);
}

sub search {
   my $self = shift;
   my ($query, $apikey, $page, $callback) = @_;

   return $self->api('search', $query, $apikey, $page, $callback);
}

sub user {
   my $self = shift;
   my ($apikey, $callback) = @_;

   return $self->api('user', '', $apikey, 1, $callback);
}

sub export {
   my $self = shift;
   my ($query, $apikey, $currentpage, $callback) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('export', $query) or return;
   $self->brik_help_run_undef_arg('export', $callback) or return;

   my $apiurl = $self->apiurl;
   my $apiargs = $self->apiargs;
   $query = URI::Escape::uri_escape_utf8($query);
   $self->log->debug("export: uri_escape_utf8 query[$query]");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   $self->log->verbose("export: using url[$apiurl]");

   my $api = '/export/';
   if ($self->master) {
      $api = '/master/export/';
   }
   my $url = $apiurl.$api.$query;
   if (defined($apiargs)) {
      $url .= $apiargs;
   }

   $self->add_headers({
      'Authorization' => "apikey $apikey",
      'Content-Type' => 'application/json',
   });

   # Abort on Ctrl+C
   my $abort = 0;
   $SIG{INT} = sub {
      #print STDERR "Ctrl+C [$abort]\n";
      $abort++;
      return 1;
   };

   # Will store incomplete line for later processing
   my $buf = '';

   # To keep state between each page of results
   my $state = {};

   my $cv = AnyEvent->condvar;

   AnyEvent::HTTP::http_get($url,
      # For each loop of processing, let callback work during 5 minutes
      # before sending a timeout.
      timeout => 300,
      headers => {
         'Authorization' => "apikey $apikey",
         'Content-Type' => "application/json",
      },
      on_body => sub {
         my ($data, $hdr) = @_;

         if ($abort > 0) {
            #print STDERR "abort\n";
            return $cv->send;
         }

         $data = $buf.$data;  # Complete from previous remaining buf

         my $status = $hdr->{Status};
         my $encoding = $hdr->{'transfer-encoding'};
         if ($status == 200 && $encoding eq 'chunked') {
            # $this will contain all lines until the last one
            # with \n ending chars. This last one will be put back
            # into $buf for next processing.
            # Thus, we only handle input stream on a line-by-line basis.
            my ($this, $tail) = $data =~ m/^(.*\n)(.*)$/s;
            # One line is not complete, add to buf and go to next:
            if (!defined($this)) {
               $buf = $data;
               return 1;
            }

            my @lines = split(/\n/, $this);
            $buf = $tail || '';

            # Put in page format
            my $page;
            for (@lines) {
               my $decode = $sj->decode($_);
               if (!defined($decode)) {
                  $self->log->error("export: unable to decode [$_]");
                  next;
               }
               next if (! $decode->{'@category'} || $decode->{'@category'} eq 'none');
               push @{$page->{results}}, $decode;
            }

            if ($page->{results} && @{$page->{results}}) {
               my $r = $callback->($page, $state);
               if (! defined($r)) {
                  return $cv->send;
               }
            }
         }
         else {
            #print STDERR "ERROR: loop: status [$status]\n";
            print $data."\n";
            return $cv->send;
         }
 
         return 1;
      },
      # Completion callback
      sub {
         my (undef, $hdr) = @_;
 
         my $status = $hdr->{Status};
         my $reason = $hdr->{Reason};
         if ($status != 200 && $status != 598) {
            $self->log->error("completion: status [$status], reason ".
               " [$reason]");
            #print Data::Dumper::Dumper($hdr)."\n";
         }

         # Handle remaining $buf if any:
         if (defined($buf) && length($buf)) {
            my @lines = split(/\n/, $buf);
            # Put in page format
            my $page;
            for (@lines) {
               my $decode = $sj->decode($_);
               if (!defined($decode)) {
                  # On abort, line may be incomplete, don't print error.
                  if (! $abort) {
                     $self->log->error("export: unable to decode remaining [$_]");
                  }
                  next;
               }
               next if (! $decode->{'@category'} || $decode->{'@category'} eq 'none');
               push @{$page->{results}}, $decode;
            }
            $callback->($page, $state) if ($page->{results} && @{$page->{results}});
         }

         return $cv->send;
      },
   );

   # Wait for termination
   return $cv->recv;
}

#
# run api::onyphe bulk /simple/datascan/ip ip.txt $cb $apikey
#
sub bulk {
   my $self = shift;
   my ($query, $apikey, $currentpage, $callback) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('bulk', $query) or return;
   $self->brik_help_run_undef_arg('bulk', $callback) or return;

   my $apiurl = $self->apiurl;
   my $apiargs = $self->apiargs;

   my ($api, $input) = $query =~ m{^\s*bulk\s*:\s*(\S+)\s+(\S+)}i;
   $self->brik_help_run_undef_arg('bulk', $api) or return;
   $self->brik_help_run_undef_arg('bulk', $input) or return;
   $self->brik_help_run_file_not_found('bulk', $input) or return;

   $self->log->verbose("bulk: api[$api] input[$input]");

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   my $body = $ft->read($input) or return;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my $url = $apiurl.'/bulk/'.$api;
   if (defined($apiargs)) {
      $url .= $apiargs;
   }

   $self->log->verbose("bulk: using url[$url]");

   $self->add_headers({
      'Authorization' => "apikey $apikey",
      'Content-Type' => 'application/json',
   });

   # Abort on Ctrl+C
   my $abort = 0;
   $SIG{INT} = sub {
      #print STDERR "Ctrl+C [$abort]\n";
      $abort++;
      return 1;
   };

   # Will store incomplete line for later processing
   my $buf = '';

   # To keep state between each page of results
   my $state = {};

   my $cv = AnyEvent->condvar;

   AnyEvent::HTTP::http_post($url, $body,
      # For each loop of processing, let callback work during 5 minutes
      # before sending a timeout.
      timeout => 300,
      headers => {
         'Authorization' => "apikey $apikey",
         'Content-Type' => "application/json",
      },
      on_body => sub {
         my ($data, $hdr) = @_;

         if ($abort > 0) {
            #print STDERR "abort\n";
            return $cv->send;
         }

         $data = $buf.$data;  # Complete from previous remaining buf

         my $status = $hdr->{Status};
         my $encoding = $hdr->{'transfer-encoding'};
         if ($status == 200 && $encoding eq 'chunked') {
            # $this will contain all lines until the last one
            # with \n ending chars. This last one will be put back
            # into $buf for next processing.
            # Thus, we only handle input stream on a line-by-line basis.
            my ($this, $tail) = $data =~ m/^(.*\n)(.*)$/s;
            # One line is not complete, add to buf and go to next:
            if (!defined($this)) {
               $buf = $data;
               return 1;
            }

            my @lines = split(/\n/, $this);
            $buf = $tail || '';

            # Put in page format
            my $page;
            for (@lines) {
               my $decode = $sj->decode($_);
               if (!defined($decode)) {
                  $self->log->error("bulk: unable to decode [$_]");
                  next;
               }
               next if (! $decode->{'@category'} || $decode->{'@category'} eq 'none');
               push @{$page->{results}}, $decode;
            }

            if ($page->{results} && @{$page->{results}}) {
               my $r = $callback->($page, $state);
               if (! defined($r)) {
                  return $cv->send;
               }
            }
         }
         else {
            #print STDERR "ERROR: loop: status [$status]\n";
            print $data."\n";
            return $cv->send;
         }

         return 1;
      },
      # Completion callback
      sub {
         my (undef, $hdr) = @_;

         my $status = $hdr->{Status};
         my $reason = $hdr->{Reason};
         if ($status != 200 && $status != 598) {
            $self->log->error("bulk: completion status [$status], reason ".
               " [$reason]");
            #print Data::Dumper::Dumper($hdr)."\n";
         }

         # Handle remaining $buf if any:
         if (defined($buf) && length($buf)) {
            my @lines = split(/\n/, $buf);
            # Put in page format
            my $page;
            for (@lines) {
               my $decode = $sj->decode($_);
               if (!defined($decode)) {
                  # On abort, line may be incomplete, don't print error.
                  if (! $abort) {
                     $self->log->error("bulk: unable to decode remaining [$_]");
                  }
                  next;
               }
               next if (! $decode->{'@category'} || $decode->{'@category'} eq 'none');
               push @{$page->{results}}, $decode;
            }
            $callback->($page, $state) if ($page->{results} && @{$page->{results}});
         }

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

Copyright (c) 2018-2021, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
