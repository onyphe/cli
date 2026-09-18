#
# $Id: Andlookup.pm,v cc13143aa17f 2026/07/09 14:59:05 james $
#
package OPP::Proc::Andlookup;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

use Text::CSV_XS;

sub _load {
   my $self = shift;
   my ($file) = @_;

   my $rows = $self->state->value('rows', $self->idx);
   my $lookup_field = $self->state->value('lookup_field', $self->idx);

   # Load CSV lookup:
   unless (defined($rows)) {
      my $csvxs = Text::CSV_XS->new({
         binary => 1,
         sep_char => ',',
         allow_loose_quotes => 1,
         allow_loose_escapes => 1,
         escape_char => '"',
      }) or die("andlookup: cannot initiate Text::CSV_XS\n");
      open(my $fd, '<', $file) or die("andlookup: cannot open file: $file\n");

      # First line is considered the header
      my $header = $csvxs->getline($fd) or die("andlookup: cannot get header\n");
      die("andlookup: no line found\n") unless defined $header;
      $lookup_field = pop @$header;  # Last field is the data to add
      my $match_fields = $header;    # Remaining columns are AND-matched, per row

      $rows = [];
      my $n = 1;  # Header was line 1
      while (my $line = $csvxs->getline($fd)) {
         $n++;
         my $tag = pop @$line;  # Last field is the data to add
         my $required = {};
         my $absent = {};
         for my $idx (0..$#$match_fields) {
            my $field = $match_fields->[$idx];
            my $cell = $line->[$idx];
            if (!defined($cell) || !length($cell)) {  # Blank: field must be absent
               $absent->{$field} = 1;
            }
            elsif ($cell eq '*') {  # Wildcard: don't check this field at all
               next;
            }
            else {
               $required->{$field} = lc($cell);
            }
         }
         unless (keys %$required || keys %$absent) {
            print STDERR "andlookup: line $n: no match criteria found, skipping\n";
            next;
         }
         push @$rows, { required => $required, absent => $absent, tag => $tag };
      }

      $self->state->add('rows', $rows, $self->idx);
      $self->state->add('lookup_field', $lookup_field, $self->idx);
   }

   return [ $rows, $lookup_field ];
}

#
# A blank cell means the field must be ABSENT from the document.
# Use '*' to skip checking a field entirely (match any value/presence):
#
# echo domain,hostname,realm,tag > lookup.csv
# echo example.com,,EXAMPLE,foo >> lookup.csv
# echo ,www.example.com,EXAMPLE,bar >> lookup.csv
# echo example.net,*,EXAMPLE,foo >> lookup.csv
#
# | andlookup lookup.csv
# | andlookup lookup.csv cidr=ip
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $file = $options->{0};
   die("andlookup: file not given\n") unless defined $file;
   die("andlookup: file not found: $file\n") unless -f $file;

   my $cidr = $options->{cidr};  # Optional: match this one field via CIDR, not exact string
   $cidr = $cidr->[0] if ref($cidr) eq 'ARRAY';

   my $r = $self->_load($file);
   my $rows = $r->[0];
   my $lookup_field = $r->[1];

   for my $row (@$rows) {
      my $matched = 1;

      for my $field (keys %{$row->{required}}) {
         my $cell = $row->{required}{$field};
         my $values = $self->value($input, $field);
         unless (defined($values)) {
            $matched = 0;
            last;
         }
         if (defined($cidr) && $field eq $cidr) {
            $matched = 0 unless grep { $self->ip_in_network($cell, $_) } @$values;
         }
         else {
            $matched = 0 unless grep { lc($_) eq $cell } @$values;
         }
         last unless $matched;
      }

      if ($matched && keys %{$row->{absent}}) {
         for my $field (keys %{$row->{absent}}) {
            if (defined($self->value($input, $field))) {
               $matched = 0;
               last;
            }
         }
      }

      $self->set($input, $lookup_field, $row->{tag}, 1) if $matched;  # As ARRAY
   }

   $self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Andlookup - andlookup processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

James Atack

=cut
