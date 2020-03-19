#
# $Id: Onyphe.pm,v d629ccff5f0c 2018/12/03 12:59:47 gomor $
#
package Metabrik::Client::Onyphe;
use strict;
use warnings;

our $VERSION = '1.04';

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
         _ao => [ qw(INTERNAL) ],
         _sb => [ qw(INTERNAL) ],
      },
      attributes_default => {
         apiurl => 'https://www.onyphe.io/api',
         autoscroll => 0,
      },
      commands => {
         simple => [ qw(api value page|OPTIONAL maxpage|OPTIONAL) ],
         search => [ qw(query page|OPTIONAL maxpage|OPTIONAL) ],
         search_where => [ qw(query where page|OPTIONAL maxpage|OPTIONAL) ],
         output_dump => [ qw(results) ],
         output => [ qw(
            results fields|OPTIONAL encode|OPTIONAL separator|OPTIONAL cb|OPTIONAL
         ) ],
         output_csv => [ qw(results fields|OPTIONAL encode|OPTIONAL) ],
         output_psv => [ qw(results fields|OPTIONAL encode|OPTIONAL) ],
         output_json => [ qw(results fields|OPTIONAL encode|OPTIONAL) ],
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

sub simple {
   my $self = shift;
   my ($api, $value, $page, $maxpage) = @_;

   $page ||= 1;
   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('simple', $api) or return;

   my $apiurl = $self->apiurl;

   my $ao = $self->_ao;
   $ao->apiurl($apiurl);

   if (! $ao->can($api)) {
      return $self->log->error("simple: api [$api] unknown");
   }

   # Special case for user API
   if ($api eq 'user') {
      return $ao->user($apikey);
   }

   $self->brik_help_run_undef_arg('simple', $value) or return;

   $self->log->verbose("simple: requesting page [$page]");

   my @r = ();
   my $results = $ao->$api($value, $apikey, $page) or return;
   push @r, @$results;

   $maxpage ||= $results->[0]{max_page} || 1;
   $self->log->verbose("simple: maxpage is [$maxpage]");

   $self->log->info("simple: page [$page/$maxpage] fetched");

   if ($self->autoscroll && ++$page <= $maxpage) {
      my $last = 0;
      $SIG{INT} = sub {
         $last = 1;
         return \@r; 
      };
      for ($page..$maxpage) {
         $self->log->verbose("simple: scrolling page [$_]");
         my $results = $ao->$api($value, $apikey, $_) or return;
         push @r, @$results;
         my $perc = sprintf("%.02f%%", $_ / $maxpage * 100);
         $self->log->info("simple: page [$_/$maxpage] fetched ($perc)...");
         last if $last;
      }
   }

   return \@r;
}

sub search {
   my $self = shift;
   my ($query, $page, $maxpage) = @_;

   $page ||= 1;
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

   my $category = lc($1);
   my $search = $2;

   my $api = 'search_'.$category;
   if (! $ao->can($api)) {
      return $self->log->error("search: category [$category] unknown");
   }

   $self->log->verbose("search: requesting page [$page]");

   my @r = ();
   my $results = $ao->$api($search, $apikey, $page) or return;
   if (ref($results) ne 'ARRAY') {
      return $self->log->error("search: not an ARRAY [".Data::Dumper::Dumper($results).
         "]");
   }
   push @r, @$results;

   $maxpage ||= $results->[0]{max_page};
   $self->log->verbose("search: maxpage is [$maxpage]");

   $self->log->info("search: page [$page/$maxpage] fetched");

   if ($self->autoscroll && ++$page <= $maxpage) {
      my $last = 0;
      $SIG{INT} = sub {
         $last = 1;
         return \@r;
      };
      for ($page..$maxpage) {
         $self->log->verbose("search: scrolling page [$_]");
         my $results = $ao->$api($search, $apikey, $_) or return;
         push @r, @$results;
         my $perc = sprintf("%.02f%%", $_ / $maxpage * 100);
         $self->log->info("search: page [$_/$maxpage] fetched ($perc)...");
         last if $last;
      }
   }

   return \@r;
}

sub _value {
   my $self = shift;
   my ($h, $field) = @_;

   my @words = split(/\./, $field);
   my $value = $h->{$words[0]};
   for (1..$#words) {
      $value = $value->{$words[$_]};
   }

   if (! defined($value)) {
      return $self->log->error("value: no value found for field [$field]");
   }

   return $value;
}

sub function_where {
   my $self = shift;
   my ($r, $where) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('function_where', $r) or return;
   $self->brik_help_run_invalid_arg('function_where', $r, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('function_where', $where) or return;

   my @new = ();

   my $return = sub {
      return [ {
         %{$r->[0]},            # Keep results information from first page only
         count => scalar(@new), # Overwrite count value
         results => \@new,      # Overwrite results value
      } ];
   };

   my $last = 0;
   $SIG{INT} = sub {
      $last = 1;
      return $return->();
   };

   for my $page (@$r) {
      for my $this (@{$page->{results}}) {
         # Update where clause with placeholder values
         my $copy = $where;
         while ($copy =~
            s{([\w\.]+)\s*:\s*\$([\w\.]+)}{$1:@{[$self->_value($this, $2)]}}) {
            #$self->log->debug("1[$1] 2[$2] value[".$self->_value($this, $2)."]");
         }
         my $this_r = $self->search($copy, 1, 1) or return;
         if ($this_r->[0]{count} > 0) {  # Check only first page of results.
            push @new, $this;            # Keep this result if matches were found.
         }
         last if $last;
      }
      last if $last;
   }

   return $return->();
}

sub function_search {
   my $self = shift;
   my ($r, $search) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('function_search', $r) or return;
   $self->brik_help_run_invalid_arg('function_search', $r, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('function_search', $search) or return;

   my @new = ();

   my $return = sub {
      return [ {
         %{$r->[0]},            # Keep results information from first page only
         count => scalar(@new), # Overwrite count value
         results => \@new,      # Overwrite results value
      } ];
   };

   my $last = 0;
   $SIG{INT} = sub {
      $last = 1;
      return $return->();
   };

   for my $page (@$r) {
      for my $this (@{$page->{results}}) {
         # Update search clause with placeholder values
         my $copy = $search;
         while ($copy =~
            s{([\w\.]+)\s*:\s*\$([\w\.]+)}{$1:@{[$self->_value($this, $2)]}}) {
         }
         my $this_r = $self->search($copy, 1, 1) or return;
         if ($this_r->[0]{count} > 0) {  # Check only first page of results.
            push @new, @{$this_r->[0]{results}}; # Keep these results if matches were found.
         }
      }
   }

   return $return->();
}

#
# Like where, but merge where results into original results.
#
sub function_merge {
   my $self = shift;
   my ($r, $argument) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('function_merge', $r) or return;
   $self->brik_help_run_invalid_arg('function_merge', $r, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('function_merge', $argument) or return;

   my @new = ();

   my $return = sub {
      return [ {
         %{$r->[0]},            # Keep results information from first page only
         count => scalar(@new), # Overwrite count value
         results => \@new,      # Overwrite results value
      } ];
   };

   my $last = 0;
   $SIG{INT} = sub {
      $last = 1;
      return $return->();
   };

   for my $page (@$r) {
      for my $this (@{$page->{results}}) {
         # Update where clause with placeholder values
         my $copy = $argument;
         while ($copy =~
            s{([\w\.]+)\s*:\s*\$([\w\.]+)}{$1:@{[$self->_value($this, $2)]}}) {
            #$self->log->debug("1[$1] 2[$2] value[".$self->_value($this, $2)."]");
         }
         my $this_r = $self->search($copy, 1, 1) or return;
         if ($this_r->[0]{count} > 0) {  # Check only first page of results.
            # Merge only first result from first page.
            my %new = ( %$this, %{$this_r->[0]{results}[0]} );
            push @new, \%new;
         }
         last if $last;
      }
      last if $last;
   }

   return $return->();
}

sub function_blacklist {
   my $self = shift;
   my ($r, $lookup) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('function_blacklist', $r) or return;
   $self->brik_help_run_invalid_arg('function_blacklist', $r, 'ARRAY')
      or return;
   $self->brik_help_run_undef_arg('function_blacklist', $lookup) or return;
   $self->brik_help_run_file_not_found('function_blacklist', $lookup)
      or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   my $l = $fc->read($lookup) or return;
   my $fields = $fc->header or return;
   my $fields_count = scalar(@$fields);

   my @new = ();

   my $return = sub {
      return [ {
         %{$r->[0]},            # Keep results information from first page only
         count => scalar(@new), # Overwrite count value
         results => \@new,      # Overwrite results value
      } ];
   };

   my $last = 0;
   $SIG{INT} = sub {
      $last = 1;
      return $return->();
   };

   for my $page (@$r) {
      for my $this (@{$page->{results}}) {
         my $skip = 0;
         for my $field (@$fields) {
            if (defined($self->_value($this, $field))) {
               for my $h (@$l) {
                  if (exists($h->{$field})
                  &&  $h->{$field} ne $self->_value($this, $field)) {
                     $skip++;
                     last;
                  }
               }
            }
            last if $skip == $fields_count;
         }
         if ($skip != $fields_count) { # Not all fields have matched,
                                       # we keep results.
            push @new, $this;
         }
      }
   }

   return $return->();
}

sub function_whitelist {
   my $self = shift;
   my ($r, $lookup) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('function_whitelist', $r) or return;
   $self->brik_help_run_invalid_arg('function_whitelist', $r, 'ARRAY')
      or return;
   $self->brik_help_run_undef_arg('function_whitelist', $lookup) or return;
   $self->brik_help_run_file_not_found('function_whitelist', $lookup)
      or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   my $l = $fc->read($lookup) or return;
   my $fields = $fc->header or return;
   my $fields_count = scalar(@$fields);

   my @new = ();

   my $return = sub {
      return [ {
         %{$r->[0]},            # Keep results information from first page only
         count => scalar(@new), # Overwrite count value
         results => \@new,      # Overwrite results value
      } ];
   };

   my $last = 0;
   $SIG{INT} = sub {
      $last = 1;
      return $return->();
   };

   for my $page (@$r) {
      for my $this (@{$page->{results}}) {
         my $skip = 0;
         for my $field (@$fields) {
            if (defined($self->_value($this, $field))) {
               for my $h (@$l) {
                  if (exists($h->{$field}) && $h->{$field} eq $self->_value($this, $field)) {
                     $skip++;
                     last;
                  }
               }
            }
            last if $skip == $fields_count;
         }
         if ($skip != $fields_count) { # No all fields have matched, we keep results.
            push @new, $this;
         }
      }
   }

   return $return->();
}

sub function_dedup {
   my $self = shift;
   my ($r, $field) = @_;

   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('function_dedup', $r) or return;
   $self->brik_help_run_invalid_arg('function_dedup', $r, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('function_dedup', $field) or return;

   my %dedup = ();
   my @new = ();
   for my $page (@$r) {
      for my $this (@{$page->{results}}) {
         my $value = $self->_value($this, $field) or next;
         # Results are ordered in latest time first, thus we keep the freshest result.
         if (! exists($dedup{$value})) {
            $dedup{$value}++;
            push @new, $this;
         }
      }
   }

   # Return new result set.
   return [ {
      %{$r->[0]},            # Keep results information from first page only
      count => scalar(@new), # Overwrite count value
      results => \@new,      # Overwrite results value
   } ];
}

# Not ready to be integrated, need to integrate -fields too and all onyphe program arguments.
#sub function_output {
#   my $self = shift;
#   my ($r, $format) = @_;

#   my $apikey = $self->apikey;
#   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
#   $self->brik_help_run_undef_arg('function_output', $r) or return;
#   $self->brik_help_run_invalid_arg('function_output', $r, 'ARRAY') or return;
#   $self->brik_help_run_undef_arg('function_output', $format) or return;

#   my $function = 'output_'.$format;
#   if (! $self->can($function)) {
#      return $self->log->error("function_output: invalid output format [$format]");
#   }

#   return $self->$function($r);
#}

sub search_pipeline {
   my $self = shift;
   my ($pipeline, $page, $maxpage) = @_;

   $page ||= 1;
   my $apikey = $self->apikey;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;
   $self->brik_help_run_undef_arg('search_pipeline', $pipeline) or return;

   my @cmd = split(/\s*\|\s*-?/, $pipeline);
   if (@cmd == 0) {
      return $self->log->error("search_pipeline: no search command found");
   }

   # First one is hopefully a search query
   my $search = shift @cmd;
   $self->log->verbose("search_pipeline: search[$search]");
   my $r = $self->search($search, $page, $maxpage) or return;

   # And others are the pipelined commands
   for my $this (@cmd) {
      $this =~ s{[\s\r\n]*$}{};
      $self->log->verbose("search_pipeline: cmd[$this]");
      my @function = $this =~ m{^(\w+)\s+(.+)$};
      if (! defined($function[0]) || ! defined($function[1])) {
         return $self->log->error("search_pipeline: parse failed for [$this]");
      }
      my $function = 'function_'.$function[0];
      my $argument = $function[1];
      if (! $self->can($function)) {
         $self->log->error("search_pipeline: unknown function [$function[0]]");
         return $r;
      }
      if (! defined($argument) || ! length($argument)) {
         $self->log->error("search_pipeline: unknown argument [$argument]");
         return $r;
      }
      $self->log->verbose("search_pipeline: function[$function] argument[$argument]");
      $r = $self->$function($r, $argument) or return;
   }

   return $r;
}

sub _rec_header_from_result {
   my $self = shift;
   my ($r, $prev) = @_;

   my %header = ();
   for my $k (keys %$r) {
      if (ref($r->{$k}) eq 'HASH') {
         my $list = $self->_rec_header_from_result($r->{$k}, $k);
         for (keys %$list) {
            $header{"$k.$_"}++;
         }
      }
      else {
         $header{$k}++;
      }
   }

   return \%header;
}

sub _build_header {
   my $self = shift;
   my ($results) = @_;

   my %header = ();
   for my $r (@$results) {
      my $ary = $r->{results};
      for my $this (@$ary) {
         my $list = $self->_rec_header_from_result($this);
         for (keys %$list) {
            $header{$_}++;
         }
      }
   }

   #print "HEADER: ".Data::Dumper::Dumper(\%header)."\n";

   return \%header;
}

sub output_dump {
   my $self = shift;
   my ($results) = @_;

   $self->brik_help_run_undef_arg('output_dump', $results) or return;
   $self->brik_help_run_invalid_arg('output_dump', $results, 'ARRAY') or return;

   return Data::Dumper::Dumper($results);
}

sub output {
   my $self = shift;
   my ($results, $fields, $encode, $sep, $cb) = @_;

   $sep ||= '|';
   $fields ||= '';
   $encode ||= '';
   $self->brik_help_run_undef_arg('output', $results) or return;
   $self->brik_help_run_invalid_arg('output', $results, 'ARRAY') or return;

   my $sb = $self->_sb;

   # Do nothing by default.
   $cb ||= sub {
      my ($line) = @_;
      return $line;
   };

   my $summary = '';
   my $header = $self->_build_header($results) or return;

   my $string;
   my $action;
   my %fields = ();
   if (length($fields)) {
      ($action, $string) = $fields =~ m{^\s*((?:\-|\+))?(.+)\s*$};
      $action ||= '+';  # Default to only keep fields given
      %fields = map { $_ => 1 } split(/\s*,\s*/, $string);
      for (keys %$header) {
         if ($action eq '+') {
            next if ($fields{$_});
            delete $header->{$_};
         }
         else {
            next if (! $fields{$_});
            delete $header->{$_};
         }
      }
   }

   my %encode = ();
   if (length($encode)) {
      %encode = map { $_ => 1 } split(/\s*,\s*/, $encode);
   }

   my @header = sort { $a cmp $b } keys %$header;
   if (@header == 0) {
      return $self->log->error("output: no header found");
   }

   print $cb->(join($sep, @header))."\n";

   for my $r (@$results) {
      my $ary = $r->{results};
      for my $this (@$ary) {
         my $line = '';
         for my $k (sort { $a cmp $b } keys %$header) {
            if (keys %fields > 0) {
               next if ($action eq '+' && ! $fields{$k});
               next if ($action eq '-' && $fields{$k});
            }

            my @words = split(/\./, $k);
            my $value = $this;

            my $count = 0;
            # Traverse the HASH to find the leaf value.
            for (@words) {
               last if (!exists($value->{$_}));
               $value = $value->{$_};
               $count++;
            }
            if ($count != @words) {  # It means there is no value for this key.
               $line .= $sep;
               next;
            }

            # Leaf value reached (maybe empty)
            if (! defined($value)) {
               $line .= $sep;
               next;
            }
            elsif (ref($value) eq 'ARRAY') {
               $line .= join(',', @$value).$sep;
            }
            else {
               if (length($encode) && exists($encode{$k})) {
                  $line .= $sb->encode($value).$sep;
               }
               else {
                  $line .= $value.$sep;
               }
            }
         }

         $line =~ s{$sep$}{};
         $line = $cb->($line);
         print "$line\n" if length($line);
      }
   }

   return $summary;
}

sub output_csv {
   my $self = shift;
   my ($results, $fields, $encode) = @_;

   $fields ||= '';
   $self->brik_help_run_undef_arg('output_csv', $results) or return;
   $self->brik_help_run_invalid_arg('output_csv', $results, 'ARRAY') or return;

   my $cb = sub {
      my ($line) = @_;
      $line =~ s{^}{"};
      $line =~ s{$}{"};
      return $line;
   };

   return $self->output($results, $fields, $encode, '","', $cb);
}

sub output_psv {
   my $self = shift;
   my ($results, $fields, $encode) = @_;

   $fields ||= '';
   $self->brik_help_run_undef_arg('output_psv', $results) or return;
   $self->brik_help_run_invalid_arg('output_psv', $results, 'ARRAY') or return;

   my $cb = sub {
      my ($line) = @_;
      $line =~ s{^\||\|$}{}g;
      return $line;
   };

   return $self->output($results, $fields, $encode, '|', $cb);
}

sub output_json {
   my $self = shift;
   my ($results) = @_;

   $self->brik_help_run_undef_arg('output_json', $results) or return;
   $self->brik_help_run_invalid_arg('output_json', $results, 'ARRAY') or return;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   return $sj->encode($results);
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
   my $results = $cli->search('category:datascan port:80');

   # Search given page of results
   my $results = $cli->search('category:datascan port:80', 10);

   # Search from page 10 to page 20 when autoscroll is active
   $cli->autoscroll(1);
   my $results = $cli->search('category:datascan port:80', 10, 20);

   # Fetch all pages when autoscroll is active
   $cli->autoscroll(1);
   my $results = $cli->search('category:datascan port:80');

   # Search using the simple API
   my $results = $cli->datascan('apache');
   my $results = $cli->reverse('8.8.8.8');

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

=item B<simple>

Use simple API for queries.

=item B<search>

Use search API for queries.

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

=item B<output_dump>

Dump output using Perl's Data::Dumper

=item B<output>

Base command to other output modes.

=item B<output_csv>

Dump output in CSV format.

=item B<output_psv>

Dump output in PSV format.

=item B<output_json>

Dump output as JSON.

=back

=head1 SEE ALSO

L<Metabrik>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2019, ONYPHE

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE

=cut
