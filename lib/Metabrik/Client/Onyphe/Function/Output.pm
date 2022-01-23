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
         process => [ qw(flat state args output) ],
      },
   };
}

#
# | output format=txt dedup=domain
# | output format=txt dedup=subnet fields=subnet
# | output format=csv header=ip,domain fields=ip,domain
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $parsed = $self->parse_v2($args);
   #print Data::Dumper::Dumper($parsed)."\n";
   my $format = $parsed->{format};
   my $fields = $parsed->{fields};
   my $dedup = $parsed->{dedup};
   my $header = $parsed->{header};

   $format = $format->[0];  # Always single option

   if ($format ne 'csv' && $format ne 'txt') {
      return $self->log->error("output: invalid output format [$format]");
   }

   if (defined($fields)) {
      $fields = { map { $_ => 1 } @$fields };
   }

   if (defined($dedup)) {
      $dedup = { map { $_ => 1 } @$dedup };
   }

   my @this_line = ();
   for my $k (sort { $a cmp $b } @{$self->fields($flat)}) {
      # Only keep wanted fields when given, otherwise use all fields:
      if (defined($fields)) {
         next unless exists($fields->{$k});
         #print "K[$k]\n";
      }

      my $values = $self->value($flat, $k);

      # Perform action against all elements of the ARRAY:
      for my $v (@$values) {
         # Build dedup key when given:
         my $key = '';
         if (defined($dedup) && exists($dedup->{$k})) {
            $key .= "$k:$v-";
         }

         # Skip when deduped:
         #print "DEDUP[$key]\n";
         next if $state->{output}{dedup}{$key};

         push @this_line, $v;

         # Update dedup cache:
         if (length($key) && !exists($state->{output}{dedup}{$key})) {
            $state->{output}{dedup}{$key}++
         }
      }
   }

   #print Data::Dumper::Dumper(\@this_line)."\n";

   if (@this_line) {
      if ($format eq 'csv' && defined($header) && !$state->{output}{header_print}) {
         my $hdr = join('","', @$header);
         print "\"$hdr\"\n";
         $state->{output}{header_print}++;
      }
      if ($format eq 'csv') {
         my $line = join('","', @this_line);
         print "\"$line\"\n";
      }
      elsif ($format eq 'txt') {
         my $line = join(',', @this_line);
         print "$line\n";
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Output - client::onyphe::function::output Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
