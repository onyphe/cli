#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Piechart;
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
         run => [ qw(page state field) ],
      },
      attributes_default => {
         last => 1,
      },
      require_modules => {
         'HTML::Show' => [ ],
         'Chart::Plotly' => [ ],
         'Chart::Plotly::Trace::Pie' => [ ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;

   my $cb = sub {
      my ($this, $state, $new) = @_;

      my $pie = Chart::Plotly::Trace::Pie->new(
         labels => [ keys %$this ],
         values => [ values %$this ],
      );

      HTML::Show::show(
         Chart::Plotly::render_full_html(data => [$pie]),
      );

      return 1;
   };

   return $self->iter($page, $cb, $state);
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Piechart - client::onyphe::function::piechart Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
