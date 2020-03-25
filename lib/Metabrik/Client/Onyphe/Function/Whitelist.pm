#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Whitelist;
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
         run => [ qw(page state csv) ],
      },
      require_modules => {
         'Metabrik::File::Csv' => [ ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $lookup) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $lookup) or return;
   $self->brik_help_run_file_not_found('run', $lookup) or return;

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

   my $cb = sub {
      my ($this, $state, $new, $lookup) = @_;

      my $skip = 0;
      # $field is the field to match against (example: domain):
      for my $field (@$csv_header) {
         # Fetch the value from current result $this:
         my $value = $self->value_as_array($this, $field) or next;

         # Compare against all fields given in the CSV:
         for my $a (@$value) {
            my $match = 0;
            for my $h (@$csv) {
               if (exists($h->{$field}) && $h->{$field} eq $a) {
                  #print "[DEBUG] skip field [$field] value [$a]\n";
                  $skip++;
                  $match++;
                  last;
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
      if ($skip == $csv_header_count) { # All fields have matched, it is
                                        # whitelisted, we keep results.
         push @$new, $this;
      }

      return 1;
   };

   return $self->iter($page, $cb, $state, $lookup);
}

1;
