#
# $Id$
#
package Metabrik::Client::Onyphe;
use strict;
use warnings;

our $VERSION = '3.00';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(client onyphe) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         callback => [ qw(callback) ],
         state => [ qw(state) ],
         # General options:
         maxpage => [ qw(value) ],
         apiurl => [ qw(apiurl) ],
         apikey => [ qw(apikey) ],
         apisize => [ qw(apisize) ],
         apitrackquery => [ qw(0|1) ],
         apikeepalive => [ qw(0|1) ],
         wait => [ qw(seconds) ],
         # API options:
         category => [ qw(category|categories) ],
         bulk => [ qw(0|1) ],
         best => [ qw(0|1) ],
         _ao => [ qw(INTERNAL) ],
         _sj => [ qw(INTERNAL) ],
      },
      attributes_default => {
         apiurl => 'https://www.onyphe.io/api/v2',
         maxpage => 1,
         wait => 1,
         state => {},
      },
      commands => {
         ao => [ ],
         pipeline => [ qw(results state OPL|OPTIONAL) ],
         user => [ qw(OPL|OPTIONAL) ],
         search => [ qw(QL) ],
         export => [ qw(QL) ],
         simple => [ qw(api QL|OPTIONAL) ],
         summary => [ qw(api QL|OPTIONAL) ],
         alert => [ qw(api arg) ],
      },
      require_modules => {
         'Data::Dumper' => [ ],
         'Metabrik::Api::Onyphe' => [ ],
         'Metabrik::String::Json' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $ao = Metabrik::Api::Onyphe->new_from_brik_init($self) or return;
   $ao->brik_init;
   $ao->user_agent("Metabrik::Client::Onyphe v$VERSION");  # Overwrite default value from $ao
   $self->_ao($ao);

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   $self->_sj($sj);

   my $cb = sub {
      my ($results, $opl) = @_;
      my $state = $self->state;
      return $self->pipeline($results, $opl, $state);
   };
   $self->callback($cb);

   return $self->SUPER::brik_init;
}

sub ao {
   my $self = shift;

   my $apiurl = $self->apiurl;
   my $apikey = $self->apikey;

   $self->_ao->apiurl($apiurl);
   $self->_ao->apikey($apikey);

   return $self->_ao;
}

sub split_ql {
   my $self = shift;
   my ($ql) = @_;

   return [] unless defined($ql);

   my ($oql, $opl) = split(/\s*\|\s*/, $ql, 2);

   #$self->log->info("split_ql: ql[$ql] oql[$oql] opl[$opl]");

   return [ $oql, $opl ];
}

#
# $self->user();
# $self->user("uniq vulnscan.cve");
#
sub user {
   my $self = shift;
   my ($ql) = @_;

   $ql = $self->split_ql($ql);

   return $self->ao->user($self->callback, $ql->[0]);
}

#
# $self->search("product:nginx");
# $self->search("product:nginx | uniq domain");
#
sub search {
   my $self = shift;
   my ($ql) = @_;

   my $category = $self->category;

   $ql = "category:$category $ql";

   my $maxpage = $self->maxpage;

   $ql = $self->split_ql($ql);

   my $apiargs = [];
   push @$apiargs, { trackquery => 'true' } if $self->apitrackquery;
   push @$apiargs, { size => $self->apisize } if $self->apisize;

   for my $page (1..$maxpage) {
      $self->ao->search(
         $ql->[0], [ { page => $page }, @$apiargs ], $self->callback, $ql->[1]);
   }

   return 1;
}

#
# $self->export("product:nginx");
# $self->export("product:nginx | uniq domain");
#
sub export {
   my $self = shift;
   my ($ql) = @_;

   my $category = $self->category;

   $ql = "category:$category $ql";

   $ql = $self->split_ql($ql);

   my $apiargs = [];
   #push @$apiargs, { keepalive => 'true' } if $self->apikeepalive;  # Not supported
   #push @$apiargs, { trackquery => 'true' } if $self->apitrackquery;  # Not supported
   push @$apiargs, { size => $self->apisize } if $self->apisize;

   return $self->ao->export($ql->[0], $apiargs, $self->callback, $ql->[1]);
}

#
# $self->simple("1.1.1.1");
# $self->simple("1.1.1.1 | uniq domain");
#
sub simple {
   my $self = shift;
   my ($ql) = @_;

   my $category = $self->category;

   $ql = $self->split_ql($ql);

   return $self->ao->simple($ql->[0], $category, $self->callback, $ql->[1]);
}

#
# $self->summary("1.1.1.1", "ip");
# $self->summary("1.1.1.1 | uniq domain", "ip");
#
sub summary {
   my $self = shift;
   my ($ql, $type) = @_;

   $ql = $self->split_ql($ql);

   return $self->ao->summary($ql->[0], $type, $self->callback, $ql->[1]);
}

sub pipeline {
   my $self = shift;
   my ($results, $opl, $state) = @_;

   my $sj = $self->_sj;

   # Prints on STDOUT as JSON:
   my $cb = sub {
      my ($results) = @_;

      my $docs = $results->{results};
      return $results if (!defined($docs) || @$docs == 0);

      for my $doc (@$docs) {
         print $sj->encode($doc)."\n";
      }

      return $results;
   };

   if (!defined($opl)) {
      return $cb->($results);
   }

   my @cmd = split(/\s*\|\s*-?/, $opl);
   if (@cmd == 0) {
      return $self->log->error("pipeline: no OPL query found");
   }

   my $last_results;
   my $last_function;
   my $last_argument;
   my $last_state;

   my $opl_cb = sub {
      my ($results, $state) = @_;

      if (!defined($results)) {
         return;
      }

      for my $this (@cmd) {
         $this =~ s{[\s\r\n]*$}{};
         $self->log->verbose("pipeline: cmd[$this]");
         my @function = $this =~ m{^(\w+)(?:\s+(.+))?$};
         if (! defined($function[0])) {
            $self->log->error("pipeline: parse failed for [$this]");
            return;
         }

         # Load function
         my $module = 'Metabrik::Client::Onyphe::Function::'.ucfirst(lc($function[0]));
         eval("use $module;");
         if ($@) {
            chomp($@);
            $self->log->error("pipeline: use function failed [$function[0]]");
            return;
         }
         my $function = $module->new_from_brik_init($self);
         if (!defined($function)) {
            $self->log->error("pipeline: load function failed [$function[0]]");
            return;
         }
         # So function can call main client::onyphe client
         $function->apiurl($self->apiurl);
         $function->apikey($self->apikey);
         # XXX: apiargs?

         my $argument = $function[1];

         if ($function->last) {
            $last_function = $function;
            $last_argument = $argument;
            $last_state = $state;
            next;
         }

         $self->log->verbose("pipeline: function[$function]");

         $results = $function->run($results, $state, $argument);
         last if (!defined($results));

         $last_results = $results;
      }

      if (defined($results)) {
         # Put back in line format
         my $docs = $results->{results};

         for my $doc (@$docs) {
            print $sj->encode($doc)."\n";
         }
      }

      # May return undefined on errors.
      return $results;
   };

   # To keep state between each page of results
   $opl_cb->($results, $state);

   if (defined($last_function) && defined($last_results)) {
      $last_function->run($last_results, $last_state, $last_argument);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe - official client for ONYPHE API access

=head1 SYNOPSIS

   use Metabrik::Client::Onyphe;

   my $cli = Metabrik::Client::Onyphe->new_brik_init;
   $cli->apikey(<APIKEY>);

   # Search first page of results only
   $cli->search('category:datascan port:80');

   # Search given page of results
   $cli->search('category:datascan port:80', 10);

   $cli->search('category:datascan port:80', 10, 20);

   $cli->export('category:datascan protocol:http');

   # Search using the simple API
   $cli->simple_datascan('apache');
   $cli->simple_resolver_reverse('8.8.8.8');

=head1 DESCRIPTION

Official client for ONYPHE API access.

=head1 ATTRIBUTES

=over 4

=item B<apikey>

=item B<apiurl>

=back

=head1 COMMANDS

=over 4

=item B<brik_properties>

=item B<brik_init>

=item B<user>

Query user license information (enpoints and categories allowed along with remaining credits).

=item B<simple> (api, value)

Use Simple API for queries (geoloc, inetnum, pastries, datascan, ...).

=item B<summary> (api, value)

Use Summary API for queries (ip, domain, hostname).

=item B<search> (query, page|OPTIONAL, maxpage|OPTIONAL)

Use Search API for queries.

=item B<export> (query)

Use Export API for queries.

=item B<pipeline>

Perform a search or export query by using | separated list of functions.

=item B<build_ao>  # XXX

=item B<split_ql>  # XXX

=item B<ao>  # XXX

=back

=head1 SEE ALSO

L<Metabrik>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, ONYPHE

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE

=cut
