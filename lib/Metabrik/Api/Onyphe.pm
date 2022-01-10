#
# $Id$
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
         apiurl => [ qw(url) ],
         apikey => [ qw(key) ],
         apiargs => [ qw(args) ],
         wait => [ qw(seconds) ],
         _sj => [ qw(INTERNAL) ],
      },
      attributes_default => {
         apiurl => 'https://www.onyphe.io/api/v2',
         wait => 1,
      },
      commands => {
        api_standard => [ qw(api oql|OPTIONAL page|OPTIONAL) ],
        api_streaming => [ qw(api oql) ],
        user => [ ],
        search => [ qw(OQL) ],
        export => [ qw(OQL callback) ],
        simple => [ qw(OQL category) ],
        summary => [ qw(OQL ip|domain|hostname) ],
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

   return $self->SUPER::brik_init;
}

sub api_standard {
   my $self = shift;
   my ($api, $oql, $page) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('api_standard', $api) or return;

   my $wait = $self->wait;

   my $apiurl = $self->apiurl;
   my $apiargs = $self->apiargs;
   $self->add_headers({
      'Authorization' => "apikey $apikey",
      'Content-Type' => 'application/json',
   });

   if (defined($oql)) {
      $oql = URI::Escape::uri_escape_utf8($oql);
      $self->log->debug("api_standard: uri_escape_utf8 oql[$oql]");
   }

   my $url = $apiurl.'/'.$api;
   if (defined($oql)) {
      $url .= '/'.$oql;
   }
   if (defined($apiargs)) {
      $url .= $apiargs;
   }
   if (defined($page)) {
      if (!defined($apiargs)) {
         $url .= '?page='.$page;
      }
      else {
         $url .= '&page='.$page;
      }
   }

   $self->log->verbose("api_standard: using url[$apiurl]");

   my $abort = 0;
   $SIG{INT} = sub {
      $abort++;
   };

   my $results;

   RETRY:

   my $res = $self->get($url);
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

   return $results;
}

sub api_streaming {
   my $self = shift;
   my ($api, $oql, $callback) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('api_streaming', $api) or return;

   my $sj = $self->_sj;
   my $apiurl = $self->apiurl;
   my $apiargs = $self->apiargs;

   if (defined($oql)) {
      $oql = URI::Escape::uri_escape_utf8($oql);
      $self->log->debug("api_streaming: uri_escape_utf8 oql[$oql]");
   }

   my $url = "$apiurl/$api/$oql";
   if (defined($apiargs)) {
      $url .= $apiargs;
   }

   $self->log->verbose("api_streaming: using url[$apiurl]");

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
               my $r = $callback->($results);
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
            $callback->($results) if ($results->{results} && @{$results->{results}});
         }

         return $cv->send;
      },
   );

   # Wait for termination
   return $cv->recv;
}

#
# $self->user();
#
sub user {
   my $self = shift;

   return $self->api_standard('user');
}

#
# $self->search("category:datascan product:nginx");
#
sub search {
   my $self = shift;
   my ($oql) = @_;

   return $self->api_standard('search', $oql);
}

#
# $self->summary("1.1.1.1", "ip");
#
sub summary {
   my $self = shift;
   my ($oql, $type) = @_;

   return $self->api_standard("summary/$type", $oql);
}

sub bulk_summary {
}

#
# $self->simple("1.1.1.1", "resolver");
#
sub simple {
   my $self = shift;
   my ($oql, $category) = @_;

   return $self->api_standard("simple/$category", $oql);
}

sub simple_best {
   my $self = shift;
   my ($oql, $category) = @_;

   return $self->api_standard("simple/$category/best", $oql);
}

sub bulk_simple {
   my $self = shift;
   my ($oql, $category, $callback) = @_;

   return $self->api_streaming("bulk/simple/$category/ip", $oql, $callback);
}

sub bulk_simple_best {
   my $self = shift;
   my ($oql, $category, $callback) = @_;

   return $self->api_streaming("bulk/simple/$category/best/ip", $oql, $callback);
}

sub alert {
}

#
# $self->export("category:datascan product:nginx");
#
sub export {
   my $self = shift;
   my ($oql, $callback) = @_;

   return $self->api_streaming('export', $oql, $callback);
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
