#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Export;
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
         run => [ qw(page state export) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $export) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $export) or return;

   my $ao_cb = sub {
      my ($results, $new) = @_;
      if (defined($results->{results}) && $results->{results} > 0) {
         # Keep this page results if matches were found.
         push @$new, @{$results->{results}};
      }
   };

   my $cb = sub {
      my ($this, $state, $new, $export) = @_;

      my $copy = $export;
      my (@holders) = $copy =~ m{[\w\.]+\s*:\s*\$([\w\.]+)}g;

      # Update where clause with placeholder values
      my %exports = ();
      for my $holder (@holders) {
         my $values = $self->value_as_array($this, $holder);
         for my $value (@$values) {
            while ($copy =~
               s{(\S+)\s*:\s*\$$holder}{$1:$value}) {
            }
            $exports{$copy}++;  # Make them unique
         }
      }

      my @exports = keys %exports;
      for my $export (@exports) {
         $self->log->verbose("export[$export]");
         $self->ao->export($export, undef, $ao_cb, $new);
      }

      return 1;
   };

   return $self->iter($page, $cb, $state, $export);
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Export - client::onyphe::function::export Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
