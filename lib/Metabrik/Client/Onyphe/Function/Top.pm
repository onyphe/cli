#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Top;
use strict;
use warnings;

use base qw(Metabrik::Client::Onyphe::Function);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(client onyphe) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes_default => {
         no_unflatten => 1,
      },
      commands => {
         process => [ qw(flat state args output) ],
      },
   };
}

#
# | top domain
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $parsed = $self->parse($args);
   my $field = $parsed->{0};
   my $count = $parsed->{1} || 10;

   my $values = $self->value($flat, $field);
   return 1 unless defined($values);

   for my $v (@$values) {
      $state->{top}{$v}++;
   }

   # Get current state so we update it:
   my $h = $state->{top};

   # Sort hash by value, highest first and stop at $count:
   my $top = 0;
   my $sort = {};
   for my $k (sort { $h->{$b} <=> $h->{$a} } keys %$h) {
      $sort->{$k} = $h->{$k};
      last if ++$top == $count;
   }

   #$self->log->info($self->dumper($state));

   $state->{top} = $sort;
   $output->[0] = $state->{top};

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Top - client::onyphe::function::top Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
