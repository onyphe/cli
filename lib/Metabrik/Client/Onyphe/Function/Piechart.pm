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
         process => [ qw(flat state args output) ],
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

sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $pie = Chart::Plotly::Trace::Pie->new(
      labels => $self->fields($flat),
      values => $self->values($flat),
   );

   HTML::Show::show(
      Chart::Plotly::render_full_html(data => [$pie]),
   );

   return 1;
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
