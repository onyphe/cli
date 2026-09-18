#
# $Id: Orlookup.pm,v caa20920d882 2026/07/03 14:12:50 james $
#
package OPP::Proc::Orlookup;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

use File::Slurp qw(read_file);
use Text::CSV_XS;
use Data::Dumper;

sub _load {
   my $self = shift;
   my ($file) = @_;

   my $csv = $self->state->value('csv', $self->idx);
   my $index = $self->state->value('index', $self->idx);
   my $match_fields = $self->state->value('match_fields', $self->idx);
   my $lookup_field = $self->state->value('lookup_field', $self->idx);

   # Load CSV lookup:
   unless (defined($csv)) {
      my $csvxs = Text::CSV_XS->new({
         binary => 1,
         sep_char => ',',
         allow_loose_quotes => 1,
         allow_loose_escapes => 1,
         escape_char => '"',
      }) or die("orlookup: cannot initiate Text::CSV_XS\n");
      #my @lines = read_file($file) or die("orlookup: cannot read or empty file: $file\n");
      open(my $fd, '<', $file) or die("orlookup: cannot open file: $file\n");

      # First line is considered the header
      my $header = $csvxs->getline($fd) or die("orlookup: cannot get header\n");
      die("orlookup: no line found\n") unless defined $header;
      #print STDERR Data::Dumper::Dumper($header)."\n";
      my $lookup = pop @$header;  # Last field is the data to add
      $lookup_field = $lookup;
      $match_fields = [ @$header ];

      while (my $line = $csvxs->getline($fd)) {
         my $last = pop @$line;  # Last field is the data to add
         #print STDERR "CSVline: ".Data::Dumper::Dumper($line)."\n";
         my $c = @$line - 1;
         #print STDERR "count: $c\n";
         for my $idx (0..$c) {
            next unless (defined($line->[$idx]) && length($line->[$idx]));
            my $field = lc($match_fields->[$idx]);
            my $value = lc($line->[$idx]);
            push @$csv, { $field => $value, $lookup_field => $last };
            # Create an index for exact O(1) keyword searches
            # Keep @$csv for CIDR searches
            push @{$index->{$field}{$value}}, $last;
         }
      }

      $self->state->add('csv', $csv, $self->idx);
      $self->state->add('index', $index, $self->idx);
      $self->state->add('match_fields', $match_fields, $self->idx);
      $self->state->add('lookup_field', $lookup_field, $self->idx);
      #print STDERR "match_fields[".Data::Dumper::Dumper($match_fields)."]\n";
      #print STDERR "lookup_field[$lookup_field]\n";
   }

   #print STDERR Data::Dumper::Dumper($csv)."\n";

   return [ $csv, $index, $match_fields, $lookup_field ];
}

#
# echo domain,tag,mytags > lookup.csv
# echo amazonaws.com,cloud,aws >> lookup.csv
#
# | orlookup lookup.csv
#
# echo ip,mytags
# echo 8.8.8.0/24,google
#
# | orlookup lookup.csv cidr=ip
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $file = $options->{0};
   die("orlookup: file not given\n") unless defined $file;
   die("orlookup: file not found: $file\n") unless -f $file;

   # Params are returned as an arrayref so get first entry in array
   my $cidr = $options->{cidr} ? $options->{cidr}[0] : 'ip';  # Use ip field by default for cidr matches

   my $r = $self->_load($file);
   my $csv = $r->[0];
   my $index = $r->[1];
   my $match_fields = $r->[2];
   my $lookup_field = $r->[3];

   #print STDERR "match_fields[".Data::Dumper::Dumper($match_fields)."]\n";
   #print STDERR "lookup_field[$lookup_field]\n";

   # Touch nothing when matching fields are not found in input:
   my $some = 0;
   for my $field (@$match_fields) {
      my $values = $self->value($input, $field);
      if (defined($values)) {  # Field found here
         $some++;
         last;
      }
   }
   unless ($some) {
      $self->output->add($input);
      return 1;
   }

   # Some fields to match against were found in input, we can search a match:
   for my $field (@$match_fields) {
      #print STDERR "field1[$field]\n";
      my $values = $self->value($input, $field) or next;
      if ($field eq $cidr) {  # CIDR match mode
         for my $v (@$values) {
            #print STDERR "field2[$field] v[$v]\n";
            for my $h (@$csv) {
               next unless $h->{$cidr};
               #print STDERR "f:". $field."\n";
               #print STDERR "h:". Data::Dumper::Dumper($h)."\n";
               #print STDERR "v:". $v."\n";
               if (defined($input->{$field}) && defined($h->{$field})) {
                  if ($self->ip_in_network($v, $h->{$field})) {
                     $self->set($input, $lookup_field, $h->{$lookup_field}, 1); # As ARRAY
                  }
               }
            }
         }
      }
      else {  # Exact match mode
         for my $v (@$values) {
            #print STDERR "field2[$field] v[$v]\n";
            my $matches = $index->{$field}{lc($v)} or next;
            for my $lookup_value (@$matches) {
               #print STDERR "match: field[$field] v[$v] lookup_field[$lookup_field]\n";
               $self->set($input, $lookup_field, $lookup_value, 1) # As ARRAY
                  if (defined($lookup_value) && length($lookup_value));
            }
         }
      }
   }

   $self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Orlookup - orlookup processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
