#
# $Id: Allowlist.pm,v 40927f2b857f 2026/06/27 07:40:48 gomor $
#
package OPP::Proc::Allowlist;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

use File::Slurp qw(read_file);
use Text::CSV_XS;

sub _load {
   my $self = shift;
   my ($file) = @_;

   my $csv = $self->state->value('csv', $self->idx);
   my $match_fields = $self->state->value('match_fields', $self->idx);

   # Load CSV lookup:
   unless (defined($csv)) {
      my $csvxs = Text::CSV_XS->new({
         binary => 1,
         sep_char => ',',
         allow_loose_quotes => 1,
         allow_loose_escapes => 1,
         escape_char => '"',
      }) or die("allowlist: cannot initiate Text::CSV_XS\n");
      #my @lines = read_file($file) or die("allowlist: cannot read or empty file: $file\n");
      open(my $fd, '<', $file) or die("allowlist: cannot open file: $file\n");

      # First line is considered the header
      my $header = $csvxs->getline($fd) or die("allowlist: cannot get header\n");
      die("allowlist: no line found\n") unless defined $header;
      #print STDERR Data::Dumper::Dumper($header)."\n";
      $match_fields = $header;  # All fields can be used in a match (AND match)

      while (my $line = $csvxs->getline($fd)) {
         my $h = {};
         my $idx = 0;
         for my $this (@$header) {
            $h->{$this} = lc($line->[$idx++]);
         }
         push @$csv, $h if keys %$h;
      }

      #print STDERR Data::Dumper::Dumper($csv)."\n";

      $self->state->add('csv', $csv, $self->idx);
      $self->state->add('match_fields', $match_fields, $self->idx);
   }

   return [ $csv, $match_fields ];
}

#
# echo domain > allowlist.csv
# echo amazonaws.com >> allowlist.csv
#
# | allowlist allowlist.csv
# | allowlist allowlist.csv cidr=ip
# | allowlist allowlist.csv regexp=hostname
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $file = $options->{0};
   die("allowlist: file not given\n") unless defined $file;
   die("allowlist: file not found: $file\n") unless -f $file;

   my $cidr = $options->{cidr} || 'ip';  # Use ip field by default for cidr matches
   my $regexp = $options->{regexp};  # No default
   $cidr = $cidr->[0] if ref($cidr) eq 'ARRAY';
   $regexp = $regexp->[0] if defined($regexp) && ref($regexp) eq 'ARRAY';
   #print STDERR "*** cidr enable on $cidr field\n" if defined($cidr);
   #print STDERR "*** regexp enable on $regexp field\n" if defined($regexp);

   my $r = $self->_load($file);
   my $csv = $r->[0];
   my $match_fields = $r->[1];

   # Touch nothing when matching fields are not found in input:
   for my $field (@$match_fields) {
      my $values = $self->value($input, $field);
      unless (defined($values)) {  # Field not found here
         return 1;  # We skip result
      }
   }

   # All fields to match against were found in input, we can search a match:
   my $skip = 0;
   my $total = @$match_fields;
   for my $line (@$csv) {
      for my $field (@$match_fields) {
         my $this_skip = 0;
         my $values = $self->value($input, $field) or next;
         if ($field eq $cidr) {  # CIDR match mode
            for my $v (@$values) {
               #print STDERR "*** match field [$field] vs v[$v]\n";
               if (defined($line->{$field}) && $self->ip_in_network($line->{$field}, $v)) {
                  $this_skip++;
               }
            }
         }
         # Regexp match mode
         elsif (defined($regexp) && $field eq $regexp) {
            for my $v (@$values) {
               my $re = $line->{$field};
               #print STDERR "*** match field [$field] vs v[$v] re[$re]\n";
               if (defined($line->{$field}) && $v =~ m{$re}i) {
                  $this_skip++;
                  last;
               }
            }
         }
         else {  # Exact field match mode
            for my $v (@$values) {
               #print STDERR "*** match field [$field] vs v[$v]\n";
               if (defined($line->{$field}) && lc($v) eq $line->{$field}) {
                  $this_skip++;
                  last;
               }
            }
         }
         $skip++ if $this_skip;
      }
   }

   #print STDERR "*** skip[$skip] total[$total]\n";

   if ($skip == $total) {  # All fields have matched, it is allowlisted
      $self->output->add($input);
   }

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Allowlist - allowlist processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
