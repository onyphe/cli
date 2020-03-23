#
# $Id: Onyphe.pm,v d629ccff5f0c 2018/12/03 12:59:47 gomor $
#
package Metabrik::Client::Onyphe;
use strict;
use warnings;

our $VERSION = '2.00';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(unstable) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         apikey => [ qw(apikey) ],
         apiurl => [ qw(apiurl) ],
         autoscroll => [ qw(0|1) ],
         wait => [ qw(seconds) ],
         master => [ qw(0|1) ],
         _ao => [ qw(INTERNAL) ],
         _sb => [ qw(INTERNAL) ],
      },
      attributes_default => {
         apiurl => 'https://www.onyphe.io/api/v2',
         autoscroll => 0,
         wait => 1,
      },
      commands => {
         user => [ ],
         simple => [ qw(api value page|OPTIONAL maxpage|OPTIONAL) ],
         summary => [ qw(api value) ],
         search => [ qw(query page|OPTIONAL maxpage|OPTIONAL) ],
         export => [ qw(query) ],
      },
      require_modules => {
         'Data::Dumper' => [ ],
         'Metabrik::Api::Onyphe' => [ ],
         'Metabrik::File::Csv' => [ ],
         'Metabrik::String::Base64' => [ ],
         'Metabrik::String::Json' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $ao = Metabrik::Api::Onyphe->new_from_brik_init($self) or return;
   $ao->user_agent("Metabrik::Client::Onyphe v$VERSION");
   $self->_ao($ao);

   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;
   $self->_sb($sb);

   return $self->SUPER::brik_init;
}

sub user {
   my $self = shift;

   my $apikey = $self->apikey;
   my $apiurl = $self->apiurl;

   my $ao = $self->_ao;
   $ao->apiurl($apiurl);

   return $ao->user($apikey);
}

sub simple {
   my $self = shift;
   my ($api, $value, $currentpage, $maxpage) = @_;

   $currentpage ||= 1;
   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('simple', $api) or return;
   $self->brik_help_run_undef_arg('simple', $value) or return;

   my $apiurl = $self->apiurl;

   my $ao = $self->_ao;
   $ao->apiurl($apiurl);

   $api = "simple_$api";
   if (! $ao->can($api)) {
      return $self->log->error("simple: api [$api] unknown");
   }

   $self->log->verbose("simple: requesting page [$currentpage]");

   my $page = $ao->$api($value, $apikey, $currentpage) or return;

   $maxpage ||= $page->{max_page} || 1;
   $self->log->verbose("simple: maxpage is [$maxpage]");

   $self->log->info("simple: page [$currentpage/$maxpage] fetched");

   if ($self->autoscroll && ++$currentpage <= $maxpage) {
      my $last = 0;
      $SIG{INT} = sub {
         $last = 1;
      };
      for ($currentpage..$maxpage) {
         $self->log->verbose("simple: scrolling page [$_]");
         $ao->$api($value, $apikey, $_) or return;
         my $perc = sprintf("%.02f%%", $_ / $maxpage * 100);
         $self->log->info("simple: page [$_/$maxpage] fetched ($perc)...");
         last if $last;
      }
   }

   return 1;
}

sub summary {
   my $self = shift;
   my ($api, $value) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('summary', $api) or return;
   $self->brik_help_run_undef_arg('summary', $value) or return;

   my $apiurl = $self->apiurl;

   my $ao = $self->_ao;
   $ao->apiurl($apiurl);

   $api = "summary_$api";
   if (! $ao->can($api)) {
      return $self->log->error("summary: api [$api] unknown");
   }

   return $ao->$api($value, $apikey);
}

sub search {
   my $self = shift;
   my ($query, $currentpage, $maxpage, $callback) = @_;

   $currentpage ||= 1;
   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('search', $query) or return;

   my $apiurl = $self->apiurl;

   my $ao = $self->_ao;
   $ao->apiurl($apiurl);

   if ($query !~ m{^\s*category\s*:\s*(\w+)\s+(.+)\s*$}i) {
      return $self->log->error("search: please start your search with ".
         "'category:CATEGORY'");
   }

   my $page = $ao->search($query, $apikey, $currentpage, $callback) or return;

   $maxpage ||= $page->{max_page};
   $self->log->verbose("search: maxpage is [$maxpage]");

   $self->log->info("search: page [$currentpage/$maxpage] fetched");

   if ($self->autoscroll && ++$currentpage <= $maxpage) {
      my $last = 0;
      $SIG{INT} = sub {
         $last = 1;
      };
      for ($currentpage..$maxpage) {
         $self->log->verbose("search: scrolling page [$_]");
         $ao->search($query, $apikey, $_, $callback) or return;
         my $perc = sprintf("%.02f%%", $_ / $maxpage * 100);
         $self->log->info("search: page [$_/$maxpage] fetched ($perc)...");
         last if $last;
      }
   }

   return 1;
}

sub export {
   my $self = shift;
   my ($query, $callback) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('export', $query) or return;

   my $apiurl = $self->apiurl;
   my $master = $self->master;

   my $ao = $self->_ao;
   $ao->apiurl($apiurl);
   $ao->master($master);

   if ($query !~ m{^\s*category\s*:\s*(\w+)\s+(.+)\s*$}i) {
      return $self->log->error("export: please start your search with ".
         "'category:CATEGORY'");
   }

   $ao->export($query, $callback, $apikey) or return;

   return 1;
}

sub export_pipeline {
   my $self = shift;
   my ($pipeline) = @_;

   $self->brik_help_run_undef_arg('export_pipeline', $pipeline) or return;

   my @cmd = split(/\s*\|\s*-?/, $pipeline);
   if (@cmd == 0) {
      return $self->log->error("export_pipeline: no search command found");
   }

   # First one is hopefully a search query
   my $query = shift @cmd;
   if ($query !~ m{^\s*category\s*:\s*(\w+)\s+(.+)\s*$}i) {
      return $self->log->error("export_pipeline: please start your search ".
         "with 'category:CATEGORY'");
   }

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   $self->log->verbose("export_pipeline: query[$query]");

   my $callback = sub {
      my ($page, $state) = @_;

      for my $this (@cmd) {
         $this =~ s{[\s\r\n]*$}{};
         $self->log->verbose("export_pipeline: cmd[$this]");
         my @function = $this =~ m{^(\w+)(?:\s+(.+))?$};
         if (! defined($function[0])) {
            printf STDERR "ERROR: export_pipeline: parse failed for [$this]\n";
            return;
         }

         # Load function
         my $module = 'Metabrik::Client::Onyphe::Function::'.
            ucfirst(lc($function[0]));
         eval("use $module;");
         if ($@) {
            chomp($@);
            printf STDERR "ERROR: export_pipeline: unknown function ".
               "[$function[0]]\n";
            return;
         }
         my $function = $module->new_from_brik_init($self);
         if (!defined($function)) {
            printf STDERR "ERROR: export_pipeline: load function failed ".
               "[$function[0]]\n";
            return;
         }

         my $argument = $function[1];

         $self->log->verbose("export_pipeline: function[$function]");

         $page = $function->run($page, $state, $argument);
         last if (!defined($page));
      }

      if (defined($page)) {
         # Put back in line format
         my $lines = $page->{results};

         for (@$lines) {
            print $sj->encode($_)."\n";
         }
      }

      return 1;
   };

   $self->export($query, $callback);

   return 1;
}

sub search_pipeline {
   my $self = shift;
   my ($pipeline, $currentpage, $maxpage) = @_;

   $currentpage ||= 1;
   $self->brik_help_run_undef_arg('search_pipeline', $pipeline) or return;

   my @cmd = split(/\s*\|\s*-?/, $pipeline);
   if (@cmd == 0) {
      return $self->log->error("search_pipeline: no search command found");
   }

   # First one is hopefully a search query
   my $query = shift @cmd;
   if ($query !~ m{^\s*category\s*:\s*(\w+)\s+(.+)\s*$}i) {
      return $self->log->error("search_pipeline: please start your search ".
         "with 'category:CATEGORY'");
   }

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   $self->log->verbose("search_pipeline: query[$query]");

   my $callback = sub {
      my ($page, $state) = @_;

      for my $this (@cmd) {
         $this =~ s{[\s\r\n]*$}{};
         $self->log->verbose("search_pipeline: cmd[$this]");
         my @function = $this =~ m{^(\w+)(?:\s+(.+))?$};
         if (! defined($function[0])) {
            printf STDERR "ERROR: search_pipeline: parse failed for [$this]\n";
            return;
         }

         # Load function
         my $module = 'Metabrik::Client::Onyphe::Function::'.
            ucfirst(lc($function[0]));
         eval("use $module;");
         if ($@) {
            chomp($@);
            printf STDERR "ERROR: search_pipeline: unknown function ".
               "[$function[0]]\n";
            return;
         }
         my $function = $module->new_from_brik_init($self);
         if (!defined($function)) {
            printf STDERR "ERROR: search_pipeline: load function failed ".
               "[$function[0]]\n";
            return;
         }

         my $argument = $function[1];

         $self->log->verbose("search_pipeline: function[$function]");

         $page = $function->run($page, $state, $argument);
         last if (!defined($page));
      }

      if (defined($page)) {
         # Put back in line format
         my $lines = $page->{results};

         for (@$lines) {
            print $sj->encode($_)."\n";
         }
      }

      return 1;
   };

   $self->search($query, $currentpage, $maxpage, $callback);

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
   $cli->autoscroll(<0|1>);

   # Search first page of results only
   my $page = $cli->search('category:datascan port:80');

   # Search given page of results
   my $page = $cli->search('category:datascan port:80', 10);

   # Search from page 10 to page 20 when autoscroll is active
   $cli->autoscroll(1);
   my $page = $cli->search('category:datascan port:80', 10, 20);

   # Fetch all pages when autoscroll is active
   $cli->autoscroll(1);
   my $page = $cli->search('category:datascan port:80');

   # Search using the simple API
   my $page = $cli->datascan('apache');
   my $page = $cli->reverse('8.8.8.8');

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

=item B<simple> (value)

Use Simple API for queries (geoloc, inetnum, pastries, datascan, ...).

=item B<summary> (value)

Use Summary API for queries (ip, domain, hostname).

=item B<search> (query)

Use Search API for queries.

=item B<export> (query)

Use Export API for queries.

=item B<function_where>

Use the where function on results returned from the search API.

=item B<function_search>

Use the search function on results returned from the search API.

=item B<function_dedup>

Use the dedup function on results returned from the search API.

=item B<function_merge>

Merge results from a where-like clause into original search results returned from the search API. Warning, the where-like clause will overwrite original fields if they exists.

=item B<function_whitelist>

Remove results that match a list of field values taken from a CSV file.

=item B<function_blacklist>

Keep results that match a list of field values taken from a CSV file.

=item B<search_pipeline>

Perform a search query by using | separated list of functions.

=item B<export_pipeline>

Perform an export query by using | separated list of functions.

=back

=head1 SEE ALSO

L<Metabrik>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2020, ONYPHE

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE

=cut
