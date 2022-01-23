#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Blacklist;
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
# echo domain > /tmp/domain.csv
# echo amazonaws.com >> /tmp/domain.csv
# | blacklist /tmp/domain.csv
#
# echo ip > /tmp/ip.csv
# echo '13.208.0.0/16' >> /tmp/ip.csv
# | blacklist /tmp/ip.csv cidr=ip'
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $parsed = $self->parse_v2($args);
   my $cidr = $parsed->{cidr} || 'ip';  # Use ip field for subnet matching by default
   my $lookup = $parsed->{0};

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

   my $skip = 0;
   # $field is the field to match against (example: domain):
   for my $field (@$csv_header) {
      # In CIDR match mode, the given field is to be matched against subnet:
      my $match_field = $field;
      if ($field eq $cidr) {
         $match_field = 'subnet';
      }

      # Fetch the value from current result $flat:
      my $values = $self->value($flat, $match_field) or next;

      # Compare against all fields given in the CSV:
      for my $a (@$values) {
         my $match = 0;
         for my $h (@$csv) {
            #print "[DEBUG] match_field [$match_field] value [".$h->{$field}."] a[$a]\n";
            if (exists($h->{$field})) {
               if ($field ne $cidr && $h->{$field} eq $a) {
                  #print "[DEBUG] skip field [$field] value [$a]\n";
                  $skip++;
                  $match++;
                  last;
               }
               elsif ($field eq $cidr && $na->match($h->{$field}, $a)) {
                  #print "[DEBUG] skip field [$field] value [$a]\n";
                  $skip++;
                  $match++;
                  last;
               }
            }
         }
         last if $match;
      }

      # When all fields have matched, no need to compare with remaining
      if ($skip == $csv_header_count) {
         #print "[DEBUG] all fields matched [$skip]\n";
         last;
      }
   }
   if ($skip != $csv_header_count) { # Not all fields have matched, it is
                                     # NOT blacklisted, we keep results
      push @$output, $flat;
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Blacklist - client::onyphe::function::blacklist Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
