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
      commands => {
         run => [ qw(page state field count|OPTIONAL) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $args) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $args) or return;

   my $arg = $self->parse($args);
   my $field = $arg->[0];
   my $count = $arg->[1] || 10;

   $self->brik_help_run_undef_arg('run', $field) or return;

   my $cb = sub {
      my ($this, $state, $new, $field, $count) = @_;

      my $value = $self->value_as_array($this, $field) or return 1;

      for my $v (@$value) {
         $state->{top}{$v}++;
      }

      my $h = $state->{top};

      # Sort hash by value, highest first and stop at $count:
      my $top = 0;
      my $sort = {};
      for my $k (sort { $h->{$b} <=> $h->{$a} } keys %$h) {
         $sort->{$k} = $h->{$k};
         last if ++$top == $count;
      }

      $state->{top} = $sort;
      $new->[0] = $state->{top};

      return 1;
   };

   return $self->iter($page, $cb, $state, $field, $count);
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
