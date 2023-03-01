#
# $Id$
#
# client::onyphe::function::filter Brik
#
package Metabrik::Client::Onyphe::Function::Filter;
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
      },
      commands => {
         process => [ qw(flat state args output) ],
      },
      require_modules => {
      },
   };
}

#
# | fieldcount domain | filter countdomain:>=3
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $parsed = $self->parse($args);
   # Example: $parsed = { countdomain => [ >=3 ] }

   for my $field (keys %$parsed) {  # Example: $field = countdomain
      my $values = $self->value($flat, $field); # Example: $values = [ 3 ]
      next unless $values;
      my $filter = $parsed->{$field};  # Example: $filter = [ >=3 ]
      $filter = $filter->[0];  # Example: $filter >= 3
      for my $this (@$values) {  # Example: $this = 3
         if ($filter =~ m{((?:>|<|>=|<=|=))(\d+)$}) {  # Example: $1 = >=, $2 = 3
            if    ($1 eq '>' ) { push @$output, $flat if $this >  $2 }
            elsif ($1 eq '>=') { push @$output, $flat if $this >= $2 }
            elsif ($1 eq '<' ) { push @$output, $flat if $this <  $2 }
            elsif ($1 eq '<=') { push @$output, $flat if $this <= $2 }
            elsif ($1 eq '=' ) { push @$output, $flat if $this == $2 }
         }
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Filter - client::onyphe::function::filter Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
