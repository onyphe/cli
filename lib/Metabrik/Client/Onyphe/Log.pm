#
# $Id$
#
# client::onyphe::log Brik
#
package Metabrik::Client::Onyphe::Log;
use strict;
use warnings;

use base qw(Metabrik::Core::Log);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(client onyphe) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         color => [ qw(0|1) ],
         level => [ qw(0|1|2|3) ],
         caller_info_prefix => [ qw(0|1) ],
         caller_verbose_prefix => [ qw(0|1) ],
         caller_warning_prefix => [ qw(0|1) ],
         caller_error_prefix => [ qw(0|1) ],
         caller_fatal_prefix => [ qw(0|1) ],
         caller_debug_prefix => [ qw(0|1) ],
         allow_log_override => [ qw(0|1) ],
      },
      attributes_default => {
         color => 1,
         level => 1,
         caller_info_prefix => 0,
         caller_verbose_prefix => 1,
         caller_warning_prefix => 1,
         caller_error_prefix => 1,
         caller_fatal_prefix => 1,
         caller_debug_prefix => 1,
         allow_log_override => 0,
      },
      commands => {
         message => [ qw(string caller|OPTIONAL) ],
         info => [ qw(string caller|OPTIONAL) ],
         verbose => [ qw(string caller|OPTIONAL) ],
         warning => [ qw(string caller|OPTIONAL) ],
         error => [ qw(string caller|OPTIONAL) ],
         fatal => [ qw(string caller|OPTIONAL) ],
         debug => [ qw(string caller|OPTIONAL) ],
      },
      require_modules => {
         'Term::ANSIColor' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   # Makes STDOUT file handle unbuffered
   my $current = select;
   select(STDOUT);
   $|++;
   select($current);

   return $self->SUPER::brik_init(@_);
}

sub message {
   my $self = shift;
   my ($text, $caller) = @_;

   $text ||= 'undef';

   my $message = '';
   if (defined($caller)) {
      $caller =~ s/^metabrik:://i;
      $caller = lc($caller);
      $message .= lc($caller).': ';
   }

   return $message."$text\n";
}

sub _print_prefix {
   my $self = shift;
   my ($str, $color) = @_;

   if ($self->color) {
      print STDERR $color, "$str ", Term::ANSIColor::RESET();
   }
   else {
      print STDERR "$str ";
   }

   return 1;
}

sub warning {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 if ($self->level < 1);

   $self->_print_prefix("[!]", Term::ANSIColor::MAGENTA());

   if ($self->caller_warning_prefix) {
      print STDERR $self->message($msg, ($caller) ||= caller());
   }
   else {
      print STDERR $self->message($msg);
   }

   return 1;
}

sub error {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 if ($self->level < 1);

   $self->_print_prefix("[-]", Term::ANSIColor::RED());

   if ($self->caller_error_prefix) {
      print STDERR $self->message($msg, ($caller) ||= caller());
   }
   else {
      print STDERR $self->message($msg);
   }

   # Returning undef is my official way of stating an error occured:
   # Number 0 is for stating a false condition occured, not not error.
   return;
}

sub fatal {
   my $self = shift;
   my ($msg, $caller) = @_;

   # In log level 0, we print nothing except fatal errors.

   $self->_print_prefix("[F]", Term::ANSIColor::RED());

   if ($self->caller_fatal_prefix) {
      die($self->message($msg, ($caller) ||= caller()));
   }
   else {
      die($self->message($msg));
   }
}

sub info {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 if ($self->level < 1);

   $self->_print_prefix("[+]", Term::ANSIColor::GREEN());

   if ($self->caller_info_prefix) {
      print STDERR $self->message($msg, ($caller) ||= caller());
   }
   else {
      print STDERR $self->message($msg);
   }

   return 1;
}

sub verbose {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 if ($self->level < 2);

   $self->_print_prefix("[*]", Term::ANSIColor::YELLOW());

   if ($self->caller_verbose_prefix) {
      print STDERR $self->message($msg, ($caller) ||= caller());
   }
   else {
      print STDERR $self->message($msg);
   }

   return 1;
}

sub debug {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 if ($self->level < 3);

   $self->_print_prefix("[D]", Term::ANSIColor::CYAN());

   if ($self->caller_debug_prefix) {
      print STDERR $self->message($msg, ($caller) ||= caller());
   }
   else {
      print STDERR $self->message($msg);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Core::Log - core::log Brik

=head1 SYNOPSIS

   use Metabrik::Core::Log;

   my $LOG = Metabrik::Core::Log->new;

=head1 DESCRIPTION

This Brik is the default logging mechanism: output on console. You could write a different logging Brik as long as it respects the API as described in the B<METHODS> paragraph below. You don't need to use this Brik directly. It is auto-loaded by B<core::context> Brik and is stored in its B<log> Attribute.

=head1 ATTRIBUTES

At B<The Metabrik Shell>, just type:

L<get core::log>

=head1 COMMANDS

At B<The Metabrik Shell>, just type:

L<help core::log>

=head1 METHODS

=over 4

=item B<brik_preinit>

=item B<brik_init>

=item B<brik_properties>

=item B<message>

=item B<info>

=item B<verbose>

=item B<warning>

=item B<error>

=item B<fatal>

=item B<debug>

=back

=head1 SEE ALSO

L<Metabrik>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
