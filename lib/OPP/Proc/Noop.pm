#
# $Id: Noop.pm,v cfbea05b0bc4 2025/01/28 15:06:19 gomor $
#
package OPP::Proc::Noop;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | noop
#
sub process {
   my $self = shift;
   my ($input) = @_;

   $self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Noop - noop processor 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
