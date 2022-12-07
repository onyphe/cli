#
# $Id$
#
package Metabrik::Client::Onyphe;
use strict;
use warnings;

our $VERSION = '3.03';

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
         apiurl => [ qw(url) ],
         apikey => [ qw(key) ],
         apisize => [ qw(size) ],
         apitrackquery => [ qw(0|1) ],
         apicalculated => [ qw(0|1) ],
         apikeepalive => [ qw(0|1) ],
         apiauth => [ qw(user:pass) ],
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
         pipeline => [ qw(results OPL state) ],
         user => [ qw(query|OPTIONAL) ],
         search => [ qw(query category|OPTIONAL maxpage|OPTIONAL) ],
         export => [ qw(query category|OPTIONAL) ],
         simple => [ qw(query category|OPTIONAL) ],
         summary => [ qw(query type|OPTIONAL) ],
         discovery => [ qw(query category|OPTIONAL) ],
         alert => [ qw(type query|OPTIONAL category|OPTIONAL name|OPTIONAL email|OPTIONAL threshold|OPTIONAL) ],
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
   my $apiauth = $self->apiauth;

   $self->brik_help_run_undef_arg('ao', $apiurl) or return;
   $self->brik_help_run_undef_arg('ao', $apikey) or return;

   $self->_ao->url($apiurl);
   $self->_ao->key($apikey);
   $self->_ao->auth($apiauth);

   return $self->_ao;
}

# Will return ethier OQL + OPL when | is used, or just OPL when none is used:
sub split_query {
   my $self = shift;
   my ($query) = @_;

   return () unless defined($query);

   my ($oql, $opl) = split(/\s*\|\s*/, $query, 2);

   my $msg = "split_query:";
   $msg .= " query[$query]" if defined($query);
   $msg .= " oql[$query]" if defined($oql);
   $msg .= " opl[$query]" if defined($opl);
   $self->log->debug($msg);

   return ( $oql, $opl );
}

#
# $self->user();
# $self->user("uniq vulnscan.cve");
#
sub user {
   my $self = shift;
   my ($query) = @_;

   my ($opl) = $self->split_query($query);

   return $self->ao->user($self->callback, $opl);
}

#
# $self->search("product:nginx");
# $self->search("product:nginx | uniq domain");
# $self->search("domain:example.com | uniq hostname", "resolver");
# $self->search("domain:example.com | uniq hostname", "resolver", 100);
#
sub search {
   my $self = shift;
   my ($query, $category, $maxpage) = @_;

   $self->brik_help_run_undef_arg("search", $query) or return;

   $category ||= $self->category;
   $maxpage ||= $self->maxpage;

   $query = "category:$category $query" unless $query =~ m{category:\S+};

   my ($oql, $opl) = $self->split_query($query);

   my $apiargs = [];
   push @$apiargs, { trackquery => 'true' } if $self->apitrackquery;
   push @$apiargs, { calculated => 'true' } if $self->apicalculated;
   push @$apiargs, { size => $self->apisize } if $self->apisize;

   for my $page (1..$maxpage) {
      last if $page > $maxpage;
      $self->ao->search($oql, [ { page => $page }, @$apiargs ], $self->callback, $opl);
      # Update maxpage with Search API results:
      $maxpage = $self->ao->_maxpage;
   }

   return 1;
}

#
# $self->export("product:nginx");
# $self->export("product:nginx | uniq domain");
# $self->export("domain:example.com | uniq hostname", "resolver");
#
sub export {
   my $self = shift;
   my ($query, $category) = @_;

   $self->brik_help_run_undef_arg("export", $query) or return;

   $category ||= $self->category;

   $query = "category:$category $query" unless $query =~ m{category:\S+};

   my ($oql, $opl) = $self->split_query($query);

   my $apiargs = [];
   #push @$apiargs, { keepalive => 'true' } if $self->apikeepalive;  # Not supported
   #push @$apiargs, { trackquery => 'true' } if $self->apitrackquery;  # Not supported
   #push @$apiargs, { calculated => 'true' } if $self->apicalculated;  # Not supported
   push @$apiargs, { size => $self->apisize } if $self->apisize;

   return $self->ao->export($oql, $apiargs, $self->callback, $opl);
}

#
# $self->simple("1.1.1.1");
# $self->simple("1.1.1.1 | uniq domain");
# $self->simple("input.txt | uniq domain");
# $self->simple("input.txt | uniq domain", "resolver");
#
sub simple {
   my $self = shift;
   my ($query, $category) = @_;

   $self->brik_help_run_undef_arg("simple", $query) or return;

   $category ||= $self->category;

   my ($oql, $opl) = $self->split_query($query);

   if ($self->bulk) {
      return $self->log->error("simple: Bulk mode selected but file [$oql] not found")
         unless -f $oql;
      my $apiargs = [];
      push @$apiargs, { keepalive => 'true' } if $self->apikeepalive;
      push @$apiargs, { trackquery => 'true' } if $self->apitrackquery;
      #push @$apiargs, { calculated => 'true' } if $self->apicalculated;  # Not supported
      push @$apiargs, { size => $self->apisize } if $self->apisize;
      return $self->best
         ? $self->ao->bulk_simple_best($oql, $category, $apiargs, $self->callback, $opl)
         : $self->ao->bulk_simple($oql, $category, $apiargs, $self->callback, $opl);
   }
   elsif ($self->best) {
      return $self->ao->simple_best($oql, $category, $self->callback, $opl);
   }

   return $self->ao->simple($oql, $category, $self->callback, $opl);
}

#
# $self->summary("1.1.1.1");
# $self->summary("1.1.1.1 | uniq domain");
# $self->summary("example.com", "domain");
#
sub summary {
   my $self = shift;
   my ($query, $type) = @_;

   $self->brik_help_run_undef_arg("summary", $query) or return;

   $type ||= "ip";

   my ($oql, $opl) = $self->split_query($query);

   if ($self->bulk) {
      return $self->log->error("summary: Bulk mode selected but file [$oql] not found")
         unless -f $oql;
      my $apiargs = [];
      push @$apiargs, { keepalive => 'true' } if $self->apikeepalive;
      push @$apiargs, { trackquery => 'true' } if $self->apitrackquery;
      #push @$apiargs, { calculated => 'true' } if $self->apicalculated;  # Not supported
      push @$apiargs, { size => $self->apisize } if $self->apisize;
      return $self->ao->bulk_summary($oql, $type, $apiargs, $self->callback, $opl);
   }

   return $self->ao->summary($oql, $type, $self->callback, $opl);
}

#
# $self->discovery("input.txt");
# $self->discovery("input.txt | uniq domain");
# $self->discovery("input.txt | uniq domain", "resolver");
#
sub discovery {
   my $self = shift;
   my ($query, $category) = @_;

   $self->brik_help_run_undef_arg("discovery", $query) or return;

   $category ||= $self->category;

   my ($oql, $opl) = $self->split_query($query);

   my $apiargs = [];
   push @$apiargs, { keepalive => 'true' } if $self->apikeepalive;
   push @$apiargs, { trackquery => 'true' } if $self->apitrackquery;
   #push @$apiargs, { calculated => 'true' } if $self->apicalculated;  # Not supported
   push @$apiargs, { size => $self->apisize } if $self->apisize;

   return $self->ao->bulk_discovery($oql, $category, $apiargs, $self->callback, $opl);
}

#
# $self->alert("list");
# $self->alert("add", "-exists:cve domain:example.com", "vulnscan", "CVE found", 'user@example.com');
# $self->alert("del", $id);
#
sub alert {
   my $self = shift;
   my ($type, $query, $category, $name, $email, $threshold) = @_;

   $self->brik_help_run_undef_arg("alert", $type) or return;

   $category ||= $self->category;

   if ($type eq "list") {
      $self->log->verbose("alert: query [$query]") if defined($query);
      $self->ao->alert($type, $query, $self->callback) or return;
   }
   elsif ($type eq "add") {
      $self->brik_help_run_undef_arg("alert", $query) or return;
      $self->brik_help_run_undef_arg("alert", $name) or return;
      $self->brik_help_run_undef_arg("alert", $email) or return;
      $query = "category:$category $query" unless $query =~ m{category:\S+};
      $self->log->verbose("alert: adding alert [$query]");
      my $post = { name => $name, email => $email, query => $query };
      $post->{threshold} = $threshold if defined($threshold);
      $self->ao->alert($type, $post, $self->callback) or return;
   }
   else {  # del
      $self->brik_help_run_undef_arg("alert", $query) or return;
      if ($query !~ m{^\d+}) {
         return $self->log->error("alert: invalid id found [$query], must be an integer");
      }
      $self->log->verbose("alert: deleting alert id [$query]");
      $self->ao->alert($type, $query, $self->callback) or return;
   }

   return 1;
}

sub pipeline {
   my $self = shift;
   my ($page, $opl, $state) = @_;

   my $sj = $self->_sj;

   # Prints on STDOUT as JSON:
   my $cb = sub {
      my ($page) = @_;

      my $docs = $page->{results};
      return $page if (!defined($docs) || @$docs == 0);

      for my $doc (@$docs) {
         print $sj->encode($doc)."\n";
      }

      return $page;
   };

   return $cb->($page) unless defined($opl);

   my @cmd = split(/\s*\|\s*-?/, $opl);
   if (@cmd == 0) {
      return $self->log->error("pipeline: no OPL query found");
   }

   my $last_page;
   my $last_function;
   my $last_argument;
   my $last_state;

   my $opl_cb = sub {
      my ($page, $state) = @_;

      return unless defined($page);

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
         # XXX: should be removed completely
         $function->apiurl($self->apiurl);
         $function->apikey($self->apikey);
         # XXX: apiargs?

         my $argument = $function[1];

         # When it is a last kind of function, we do not continue processing
         # the pipeline and just skip whatever is following:
         if ($function->last) {
            $last_function = $function;
            $last_argument = $argument;
            $last_state = $state;
            next;
         }

         $self->log->verbose("pipeline: function[$function]");

         $page = $function->run($page, $state, $argument);
         last unless defined($page);

         $last_page = $page;
      }

      if (defined($page)) {
         # Put back in line format
         my $docs = $page->{results};

         for my $doc (@$docs) {
            print $sj->encode($doc)."\n";
         }
      }

      # May return undefined on errors.
      return $page;
   };

   # To keep state between each page of results
   $opl_cb->($page, $state);

   if (defined($last_function) && defined($last_page)) {
      $last_function->run($last_page, $last_state, $last_argument);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe - official client for ONYPHE API access with OPL support

=head1 SYNOPSIS

   use Metabrik::Client::Onyphe;

   my $cli = Metabrik::Client::Onyphe->new_brik_init();
   $cli->apikey(<APIKEY>);

   # All methods will print results on STDOUT once query has been processed through pipeline

   # Show user profile information, like which APIs are allowed, which category of information
   # or other informations like scanned ports or checked vulnerabilities:
   $cli->user();
   # Just display CVEs checked by vulnscan:
   $cli->user("uniq vulnscan.cve");
   # Just display TCP ports scanned:
   $cli->user("uniq ports.tcp");

   # Search all Nginx exposed found in datascan category:
   $cli->search("product:nginx");
   # Enumerate all unique domains which have an Nginx server exposed:
   $cli->search("product:nginx | uniq domain");
   # Enumerate all unique hostnames (FQDNs) found from resolver category:
   $cli->search("domain:example.com | uniq hostname", "resolver");
   # Iterate over all 1000 maximum pages available to Search API:
   $cli->search("domain:example.com | uniq hostname", "resolver", 1000);

   # Export all Apache servers running on Windows from datascan category:
   $cli->export("os:windows productvendor:apache");
   # Export all subject.organization from ctl category:
   $cli->export("-exists:subject.organization", "ctl");
   # Build a unique list of all domains belonging to the .top tld from ctl category:
   $cli->export("tld:top -exists:domain | uniq domain", "ctl");

   # Query the Simple API for information found in datascan category for 8.8.8.8:
   $cli->simple("8.8.8.8");
   # Search all unique domains found in datascan category for 8.8.8.8:
   $cli->simple("8.8.8.8 | uniq domain");
   # Search all unique domains found in resolver category for 8.8.8.8:
   $cli->simple("8.8.8.8 | uniq domain", "resolver");
   # Perform Bulk Simple API calls:
   system("echo 1.1.1.1 > /tmp/input.txt");
   system("echo 2.2.2.2 >> /tmp/input.txt");
   system("echo 3.3.3.3 >> /tmp/input.txt");
   $cli->best(0);
   $cli->bulk(1);
   $cli->simple("input.txt | uniq domain", "resolver");

   # Search the best match for given input using Bulk Simple Best API and whois category:
   $cli->best(1);
   $cli->bulk(1);
   system("echo 1.1.1.1 > /tmp/input.txt");
   system("echo 2.2.2.2 >> /tmp/input.txt");
   system("echo 3.3.3.3 >> /tmp/input.txt");
   $cli->simple("input.txt", "whois");

   # Query the Summary API for the given asset type and IP address:
   $cli->summary("8.8.8.8", "ip");
   # Query the Summary API and perform OPL further processing:
   $cli->summary("8.8.8.8 | uniq domain", "ip");

   # Query the Discovery API, always in bulk mode:
   $cli->discovery("input.txt | uniq domain");
   # Query the Discovery API, always in bulk mode, against resolver category:
   $cli->discovery("input.txt | uniq domain", "resolver");

   # List alerts by using the Alert API:
   $cli->alert("list");

=head1 DESCRIPTION

Official client for ONYPHE API access with OPL support. OPL is ONYPHE Processing Language, a pipeline used to pass results from a function to another for specific processing on client side. That allows, for instance, to perform correlation between multiple categories of information.

Thus, an input query is split between the OQL (ONYPHE Query Language) and the OPL. OQL is executed server-side via ONYPHE API while OPL is executed client-side, except for a few functions which are able to call the ONYPHE API again by using previous function results (correlation support).

=head1 ATTRIBUTES

=over 4

=item B<maxpage> (N)

When using Search API, perform autoscroll on a number of paged results. Default: 1.

=item B<wait> (seconds)

Wait time between each requests to avoid hitting rate limit. Default: 1.

=item B<category> (category)

Select which category of information to query. Default: datascan or geoloc, depending on the API used.

=item B<bulk> (0|1)

Activate bulk request mode for APIs supporting that feature. Default: 0.

=item B<best> (0|1)

Activate best request mode for APIs supporting that feature. Default: 0.

=item B<apikey> (key)

Your client API key. Default: none.

=item B<apiurl> (url)

ONYPHE API endpoint. Default: https://www.onyphe.io/api/v2

=item B<apisize> (N)

Number of results to return per page. Default: 10.

=item B<apitrackquery> (0|1)

Activate track query mode: it will add a trackquery field to results. Default: 0.

=item B<apicalculated> (0|1)

Activate calculated fields mode: it will add a calculated field to results. Default: 0.

=item B<apikeepalive> (0|1)

Activate keep alive mode: it will print some dummy results on API calls when nothing has been rendered to support long running API calls. Default: 0.

=back

=head1 COMMANDS

=over 4

=item B<brik_properties>

Internal method.

=item B<brik_init>

Internal method.

=item B<user> (OPL)

Query user license information (enpoints and categories allowed along with remaining credits, for instance). Allowed to perform OPL further processing on output.

=item B<simple> (query, category|OPTIONAL)

Use Simple API for queries (geoloc, inetnum, pastries, datascan, ...). Allowed to perform OPL further processing on output.

=item B<summary> (query, type|OPTIONAL)

Use Summary API for queries. Type is optional and is like ip, domain or hostname (defaults to ip type).  Allowed to perform OPL further processing on output.

=item B<search> (query, category|OPTIONAL, maxpage|OPTIONAL)

Use the Search API for queries. Category and maxpage are optional and respectively defaults to datascan and maxpage 1. Allowed to perform OPL further processing on output.

=item B<export> (query, category|OPTIONAL)

Use Export API for queries. Category is optional and defaults to datascan. Allowed to perform OPL further processing on output.

=item B<pipeline> (results, OPL, state)

Allows to perform additional OPL processing against output from API calls. State between each processing loop can be retained by using the state object.

=item B<ao>

api::onyphe Brik object.

=item B<split_query> (query)

Split query in two scalars: OQL & OPL to let OQL be used in API calls and OPL within the function pipeline.

=item B<alert> (list)

=item B<alert> (add, query, category, name, email, threshold|OPTIONAL)

=item B<alert> (del, id)

=item B<discovery> (query, category|OPTIONAL)

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
