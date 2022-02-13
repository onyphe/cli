#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Exec;
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
      require_modules => {
         'Metabrik::File::Json' => [ ],
         'Metabrik::String::Random' => [ ],
         'Metabrik::Shell::Command' => [ ],
      },
   };
}

#
# Note: myscript.sh will take the input doc from an input file as only argument
#
# | exec myscript.pl
#
sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $parsed = $self->parse($args);
   my $command = $parsed->{0};

   my $jf = Metabrik::File::Json->new_from_brik_init($self) or return;
   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;
   my $sr = Metabrik::String::Random->new_from_brik_init($self) or return;

   my $file = $sr->filename;
   $jf->write($self->unflatten($flat), $file) or return;
   $sc->execute($command, $file) or return;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Exec - client::onyphe::function::exec Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
