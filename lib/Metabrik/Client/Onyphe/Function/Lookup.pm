#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Lookup;
use strict;
use warnings;

use base qw(Metabrik::Client::Onyphe::Function);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(client onyphe) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         _csv => [ qw(INTERNAL) ],
         _csv_header => [ qw(INTERNAL) ],
         _csv_header_count => [ qw(INTERNAL) ],
      },
      commands => {
         process => [ qw(flat state args output) ],
      },
      require_modules => {
         'Metabrik::File::Csv' => [ ],
         'Metabrik::Network::Address' => [ ],
      },
   };
}

#
# echo domain,mytags > lookup.csv
# echo amazonaws.com,aws >> lookup.csv
#
# | lookup lookup.csv
#
# echo ip,mytags
# echo 8.8.8.0/24,google
#
# | lookup lookup.csv cidr=ip merge=true
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $parsed = $self->parse($args);
   # Use ip field for subnet matching by default
   my $cidr = (defined($parsed->{cidr}) && $parsed->{cidr}[0]) || 'ip';
   my $merge = $parsed->{merge} ? 1 : 0;
   my $lookup = $parsed->{0};

   return $self->log->error("lookup: no lookup file given") unless defined($lookup);
   $self->brik_help_run_file_not_found('process', $lookup) or return;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;

   my $csv;
   my $csv_header;
   my $csv_header_count;
   if (!defined($self->_csv)) {
      my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
      $csv = $fc->read($lookup) or return;
      $csv_header = $fc->header or return;
      $csv_header_count = scalar(@$csv_header);
      $self->_csv($csv);
      $self->_csv_header($csv_header);
      $self->_csv_header_count($csv_header_count);
   }
   else {
      $csv = $self->_csv;
      $csv_header = $self->_csv_header;
      $csv_header_count = $self->_csv_header_count;
   }

   # $field is the field to match against (example: domain):
   for my $field (@{$self->fields($flat)}) {
      # In CIDR match mode, the given field is to be matched against subnet:
      my $match_field = $field;
      if ($field eq $cidr) {
         $match_field = 'subnet';
      }

      # Fetch the value from current result $flat:
      my $values = $self->value($flat, $match_field) or next;

      # Lookup against all fields given in the CSV:
      for my $a (@$values) {
         for my $h (@$csv) {
            if (exists($h->{$field})) {
               #print "[DEBUG] lookup [$field] value [$a] hfield [".$h->{$field}."]\n";
               #print "[DEBUG] cidr [$cidr] lookup found [$field] value [$a]\n";
               if ($field ne $cidr && $h->{$field} eq $a) {
                  #print "[DEBUG] lookup found [$field] value [$a]\n";
                  if ($merge) {
                     $flat = { %{$self->clone($flat)}, %$h };
                  }
                  else {
                     push @{$flat->{lookup}}, $h;
                  }
               }
               elsif ($field eq $cidr && $na->match($a, $h->{$field})) {
                  #print "[DEBUG] cidr lookup found [$field] value [$a]\n";
                  if ($merge) {
                     my $new_h = $self->clone($h);
                     delete $new_h->{$cidr};  # Don't merge CIDR matching field
                     $flat = { %{$self->clone($flat)}, %$new_h };
                  }
                  else {
                     push @{$flat->{lookup}}, $h;
                  }
               }
            }
         }
      }
   }

   push @$output, $flat;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Lookup - client::onyphe::function::lookup Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
