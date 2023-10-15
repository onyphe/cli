#
# $Id: Addfield.pm,v 3c62c12dda1e 2023/09/10 07:48:40 gomor $
#
package OPP::Proc::Addfield;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

#
# | addfield scope=target mytag=test
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;

   my %fields = ();
   for my $k (keys %$options) {
      next if $k eq 'args';
      next unless defined($options->{$k});
      $fields{$k} = $options->{$k}[0] if defined($options->{$k}[0]);
   }

   for my $k (keys %fields) {
      next unless defined($fields{$k});
      $input->{$k} = $fields{$k};
   }

   $self->output->add($input);

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Addfield - addfiel processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
