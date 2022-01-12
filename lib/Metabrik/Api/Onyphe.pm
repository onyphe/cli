#
# $Id$
#
# api::onyphe Brik
#
package Metabrik::Api::Onyphe;
use strict;
use warnings;

our $VERSION = '3.00';

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision: 31687a060e97 $',
      tags => [ qw(client onyphe) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         apiurl => [ qw(url) ],
         apikey => [ qw(key) ],
         wait => [ qw(seconds) ],
         _sj => [ qw(INTERNAL) ],
      },
      attributes_default => {
         apiurl => 'https://www.onyphe.io/api/v2',
         wait => 1,
      },
      commands => {
         api_standard => [ qw(
            request api oql|OPTIONAL apiargs|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         api_streaming => [ qw(
            request api oql apiargs|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         user => [ qw(cb|OPTIONAL cb_arg|OPTIONAL) ],
         search => [ qw(OQL apiargs|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         summary => [ qw(ip|domain|hostname OQL|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         simple => [ qw(OQL category|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         simple_best => [ qw(OQL category|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         export => [ qw(OQL apiargs|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         alert => [ qw(list|add|del OQL|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         bulk_summary => [ qw(
            ip|domain|hostname OQL apiargs|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         bulk_simple => [ qw(
            OQL category|OPTIONAL apiargs|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
         bulk_simple_best => [ qw(
            OQL category|OPTIONAL apiargs|OPTIONAL cb|OPTIONAL cb_arg|OPTIONAL) ],
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

sub brik_init {
   my $self = shift;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   $self->_sj($sj);

   $self->user_agent("Metabrik::Api::Onyphe v$VERSION");

   return $self->SUPER::brik_init;
}

sub api_standard {
   my $self = shift;
   my ($req, $api, $oql, $apiargs, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg('api_standard', $req) or return;
   $self->brik_help_run_undef_arg('api_standard', $api) or return;

   my $sj = $self->_sj;
   my $wait = $self->wait;
   my $apiurl = $self->apiurl;
   my $apikey = $self->apikey;

   $self->add_headers({
      'Authorization' => "apikey $apikey",
      'Content-Type' => 'application/json',
   });

   if ($req eq "GET" && defined($oql)) {
      $oql = URI::Escape::uri_escape_utf8($oql);
      $self->log->debug("api_standard: uri_escape_utf8 oql[$oql]");
   }

   my $url = $apiurl.'/'.$api;
   if ($req eq "GET" && defined($oql)) {
      $url .= '/'.$oql;
   }
   if (defined($apiargs)) {
      my @args = ();
      for my $arg (@$apiargs) {
         for my $k (sort { $a cmp $b } keys %$arg) {
            push @args, $k.'='.$arg->{$k};
         }
      }
      $url .= '?'.join('&', @args);
   }

   $self->log->verbose("api_standard: using url[$url]");

   my $abort = 0;
   $SIG{INT} = sub {
      #print STDERR "Ctrl+C [$abort]\n";
      $abort++;
      return 1;
   };

   my $results;

   RETRY:

   my $res = $req eq "GET" ? $self->get($url)
      : $self->post(defined($oql) ? $sj->encode($oql) : undef, $url);

   my $code = $self->code;
   if ($code == 429) {
      $self->log->warning("api_standard: request limit reached, waiting before retry");
      if (defined($wait) && $wait > 0) {
         sleep($wait);
      }
      goto RETRY;
   }
   elsif ($code == 400) {
      $results = $self->content;
      $self->log->error("api_standard: bad request: ".$results->{text});
   }
   elsif ($code == 200) {
      $results = $self->content;
      $self->log->info("api_standard: success");
   }
   else {
      $self->log->error("api_standard: code [$code], waiting before retry");
      if (defined($wait) && $wait > 0) {
         sleep($wait);
      }
      goto RETRY;
   }

   if ($abort) {
      return;
   }

   return $cb->($results, $cb_arg);
}

sub api_streaming {
   my $self = shift;
   my ($req, $api, $oql, $apiargs, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("api_streaming", $req) or return;
   $self->brik_help_run_undef_arg("api_streaming", $api) or return;
   $self->brik_help_run_undef_arg("api_streaming", $oql) or return;

   my $sj = $self->_sj;
   my $apiurl = $self->apiurl;
   my $apikey = $self->apikey;

   if ($req eq "GET" && defined($oql)) {
      $oql = URI::Escape::uri_escape_utf8($oql);
      $self->log->debug("api_streaming: uri_escape_utf8 oql[$oql]");
   }

   my $url = "$apiurl/$api";
   if ($req eq "GET") {
      $url .= "/$oql";
   }
   if (defined($apiargs)) {
      my @args = ();
      for my $arg (@$apiargs) {
         for my $k (sort { $a cmp $b } keys %$arg) {
            push @args, $k.'='.$arg->{$k};
         }
      }
      $url .= '?'.join('&', @args);
   }

   $self->log->verbose("api_streaming: using url[$url]");

   # Abort on Ctrl+C
   my $abort = 0;
   $SIG{INT} = sub {
      #print STDERR "Ctrl+C [$abort]\n";
      $abort++;
      return 1;
   };

   # Will store incomplete line for later processing
   my $buf = '';

   my $cv = AnyEvent->condvar;

   my @args = ( $url );
   if ($req eq "POST") {
      push @args, $oql;
   }
   push @args,
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

            my @docs = split(/\n/, $this);
            $buf = $tail || '';

            # Put in page format to unify different APIs output:
            my $results;
            for (@docs) {
               my $decode = $sj->decode($_);
               if (!defined($decode)) {
                  $self->log->error("export: unable to decode [$_]");
                  next;
               }
               next if (! $decode->{'@category'} || $decode->{'@category'} eq 'none');
               push @{$results->{results}}, $decode;
            }

            if ($results->{results} && @{$results->{results}}) {
               my $r = $cb->($results, $cb_arg);
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
            my @docs = split(/\n/, $buf);
            # Put in page format
            my $results;
            for (@docs) {
               my $decode = $sj->decode($_);
               if (!defined($decode)) {
                  # On abort, line may be incomplete, don't print error.
                  if (! $abort) {
                     $self->log->error("export: unable to decode remaining [$_]");
                  }
                  next;
               }
               next if (! $decode->{'@category'} || $decode->{'@category'} eq 'none');
               push @{$results->{results}}, $decode;
            }
            $cb->($results, $cb_arg) if ($results->{results} && @{$results->{results}});
         }

         return $cv->send;
      },
   ;

   $req eq "GET" ? AnyEvent::HTTP::http_get(@args)
                 : AnyEvent::HTTP::http_post(@args);

   # Wait for termination
   $cv->recv;

   return 1;
}

sub callback {
   my $self = shift;

   return sub {
      my ($results) = @_;

      return unless defined($results);

      my $sj = $self->_sj;

      # Paged result mode:
      my $docs;
      if (exists($results->{results})) {
         $docs = $results->{results};
      }
      # Streamed result mode:
      else {
         $docs = $results;
      }

      for my $doc (@$docs) {
         my $this = $sj->encode($doc);
         if (!defined($this)) {
            $self->log->error("callback: unable to encode [$doc]");
            next;
         }
         next if (! $doc->{'@category'} || $doc->{'@category'} eq 'none');
         print "$this\n";
      }

      return $docs;
   };
}

#
# $self->user();
#
sub user {
   my $self = shift;
   my ($cb, $cb_arg) = @_;

   $cb ||= $self->callback;

   return $self->api_standard("GET", "user", undef, undef, $cb, $cb_arg);
}

#
# $self->search("category:datascan product:nginx");
# $self->search("category:datascan product:nginx", 10);
#
sub search {
   my $self = shift;
   my ($oql, $apiargs, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("search", $oql) or return;

   $apiargs ||= { page => 1 };
   $cb ||= $self->callback;

   return $self->api_standard("GET", "search", $oql, $apiargs, $cb, $cb_arg);
}

#
# $self->summary("ip", "1.1.1.1");
#
sub summary {
   my $self = shift;
   my ($type, $oql, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("summary", $type) or return;
   $self->brik_help_run_undef_arg("summary", $oql) or return;

   $cb ||= $self->callback;

   return $self->api_standard("GET", "summary/$type", $oql, undef, $cb, $cb_arg);
}

# keepalive=true
# trackquery=true
# size=true

#
# $self->bulk_summary("ip", "input.txt");
# $self->bulk_summary("ip", "input.txt", [{ size => 100 }, { keepalive => 1 }]);
#
sub bulk_summary {
   my $self = shift;
   my ($type, $input, $apiargs, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("bulk_summary", $type) or return;
   $self->brik_help_run_undef_arg("bulk_summary", $input) or return;

   $cb ||= $self->callback;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   my $body = $ft->read($input) or return;

   return $self->api_streaming(
      "POST", "bulk/summary/$type", $body, $apiargs, $cb, $cb_arg);
}

#
# $self->simple("1.1.1.1");
# $self->simple("1.1.1.1", "resolver");
#
sub simple {
   my $self = shift;
   my ($oql, $category, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("simple", $oql) or return;

   $category ||= "datascan";
   $cb ||= $self->callback;

   return $self->api_standard("GET", "simple/$category", $oql, undef, $cb, $cb_arg);
}

sub simple_best {
   my $self = shift;
   my ($oql, $category, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("simple_best", $oql) or return;

   $category ||= "geoloc";
   $cb ||= $self->callback;

   return $self->api_standard("GET", "simple/$category/best", $oql, undef, $cb, $cb_arg);
}

#
# All Bulk requests can take the following arguments
#
# keepalive=true
# trackquery=true
# size=true
#

#
# $self->bulk_simple("input.txt", "resolver");
# $self->bulk_simple("input.txt", "resolver", [ { size => 100 }, { keepalive => 1 }]);
#
sub bulk_simple {
   my $self = shift;
   my ($input, $category, $apiargs, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("bulk_simple", $input) or return;

   $category ||= "datascan";
   $cb ||= $self->callback;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   my $body = $ft->read($input) or return;

   return $self->api_streaming(
      "POST", "bulk/simple/$category/ip", $body, $apiargs, $cb, $cb_arg);
}

#
# $self->bulk_simple_best("input.txt, "geoloc");
#
sub bulk_simple_best {
   my $self = shift;
   my ($input, $category, $apiargs, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("bulk_simple_best", $input) or return;

   $category ||= "geoloc";
   $cb ||= $self->callback;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   my $body = $ft->read($input) or return;

   return $self->api_streaming(
      "POST", "bulk/simple/$category/best/ip", $body, undef, $cb, $cb_arg);
}

#
# $self->alert("list");
# $self->alert("add", "category:vulnscan -exists:cve domain:example.com",
#    "Critical CVE on example.com", 'user@example.com');
# $self->alert("add", "category:datascan protocol:vnc",
#    "Low VNC", 'user@example.com', '<1000');
# $self->alert("del", $id);
#
sub alert {
   my $self = shift;
   my ($type, $oql, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("alert", $type) or return;

   $cb ||= $self->callback;

   if ($type eq "list") {
      return $self->api_standard("GET", "alert/$type", undef, undef, $cb, $cb_arg);
   }
   elsif ($type eq "add") {
      return $self->api_standard("POST", "alert/$type", $oql, undef, $cb, $cb_arg);
   }
   elsif ($type eq "del") {
      return $self->api_standard("POST", "alert/$type/$oql", {}, undef, $cb, $cb_arg);
   }
   else {
      $self->log->error("alert: unknown type given [$type], choose between: ".
         "list, add or del");
   }

   return 1;
}

#
# $self->export("category:datascan product:nginx");
#
sub export {
   my $self = shift;
   my ($oql, $apiargs, $cb, $cb_arg) = @_;

   $self->brik_help_run_undef_arg("export", $oql) or return;

   $cb ||= $self->callback;

   return $self->api_streaming("GET", "export", $oql, $apiargs, $cb, $cb_arg);
}

1;

__END__

=head1 NAME

Metabrik::Api::Onyphe - api::onyphe Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
