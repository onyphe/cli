#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Output;
use strict;
use warnings;

use base qw(Metabrik::Client::Onyphe::Function);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(client onyphe) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         run => [ qw(page state format) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $args) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $args) or return;

   my $arg = $self->parse_v2($args);
   #print Data::Dumper::Dumper($arg)."\n";
   my $format = $arg->{format};
   my $fields = $arg->{fields};
   my $dedup = $arg->{dedup};
   my $header = $arg->{header};

   $self->brik_help_run_undef_arg('run', $format) or return;

   $format = $format->[0];  # Always single option

   if ($format ne 'csv') {
      return $self->log->error("function_output: invalid output format [$format]");
   }

   if (defined($fields)) {
      $fields = { map { $_ => 1 } @$fields };
   }

   if (defined($dedup)) {
      $dedup = { map { $_ => 1 } @$dedup };
   }

   my $cb = sub {
      my ($this, $state, $new, $format, $fields, $dedup) = @_;

      #print Data::Dumper::Dumper($this)."\n";

      my @this_line = ();
      for my $k (sort { $a cmp $b } keys %$this) {
         # Only keep wanted fields when given, otherwise use all fields:
         if (defined($fields)) {
            next unless exists($fields->{$k});
         }

         # Make it always an ARRAY:
         my $ary = (ref($this->{$k}) eq 'ARRAY') ? $this->{$k} : [ $this->{$k} ];

         # Perform action against all elements of the ARRAY:
         for my $e (@$ary) {
            # Build dedup key when given:
            my $key = '';
            if (defined($dedup) && exists($dedup->{$k})) {
               $key .= "$k:$e-";
            }

            # Skip when deduped:
            #print "DEDUP[$key]\n";
            next if $state->{output}{dedup}{$key};

            push @this_line, $e;

            # Update dedup cache:
            if (length($key) && !exists($state->{output}{dedup}{$key})) {
               $state->{output}{dedup}{$key}++
            }
         }
      }

      #print Data::Dumper::Dumper(\@this_line)."\n";

      for (@this_line) {
         if (defined($header) && !$state->{output}{header_print}) {
            my $hdr = join('","', @$header);
            print "\"$hdr\"\n";
            $state->{output}{header_print}++;
         }
         print "\"$_\"\n";
      }

      return 1;
   };

   return $self->iter($page, $cb, $state, $format, $fields, $dedup);
}

1;
