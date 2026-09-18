#
# $Id: Apic.pm,v 40927f2b857f 2026/06/27 07:40:48 gomor $
#
package Onyphe::Apic;
use strict;
use warnings;

#
# NOTE: this module will replace Onyphe::Api at some point, thus will be renamed to
# Onyphe::Api when migration to new scheme is finished.
#

our $VERSION = '4.20.1';

use experimental qw(signatures);

use base qw(Onyphe);

our @AS = qw(endpoint apikey username password _ua);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildIndices;

use Data::Dump qw(dump);

use Mojo::URL;
use Mojo::UserAgent;
use File::Slurp qw(read_file);

sub ua ($self) {
   return $self->_ua if defined($self->_ua);

   my $ua = Mojo::UserAgent->new;
   $ua->connect_timeout(10);
   $ua->inactivity_timeout(60);
   $ua->request_timeout(30);
   #$ua->request_timeout(5);
   $ua->max_connections(5);  # Concurrent connections to keep alive
   $ua->transactor->name('ONYPHE API Common v'.$VERSION);

   return $self->_ua($ua);
}

sub url ($self, $path) {
   $path =~ s{^/*}{}g;

   my $baseurl = $self->get_baseurl;
   my $url = Mojo::URL->new($baseurl.'/'.$path);

   return $url;
}

sub headers ($self, $apikey, $ct = undef) {
   my $headers = {
      'Authorization' => 'Bearer '.$apikey,
      'X-Api-Key' => $apikey,  # Ready for APIv3
      #'Content-Type' => 'application/json; charset=utf-8',
      'Content-Type' => 'application/json',
      'Accept' => '*/*',
   };
   if (defined($ct)) {
      $headers->{'Content-Type'} = $ct;
   }
   return $headers;
}

sub params ($self, $params = undef) {
   return '' unless defined($params);
   my $first = 1;
   my $args = '';
   for my $k (keys %$params) {
      my $v = $params->{$k};
      my $op = '?';
      $op = '&' unless $first;
      $args .= $op.$k.'='.$v;
      $first = 0;
   }
   return $args;
}

sub get ($self, $ua, $url, $headers = undef) {
   my @args = ( $url );
   push @args, $headers if defined($headers);
   return $ua->get(@args);
}

sub post ($self, $ua, $url, $headers = undef) {
   my @args = ( $url );
   push @args, $headers if defined($headers);
   return $ua->post(@args);
}

sub post_content ($self, $ua, $url, $headers = undef, $content = undef) {
   my @args = ( $url );
   push @args, $headers if defined($headers);
   push @args, ( $content );
   #print dump(\@args)."\n";
   return $ua->post(@args);
}

sub load_input ($self, $input) {
   # Make sure we don't touch anything from this file when loading:
   my @lines = read_file($input, { binmode => ':raw' });
   return \@lines;
}

sub is_error ($self, $tx) {
   return 1 unless defined($tx->res);
   return 1 if defined($tx->res->error);
   return 0;
}

1;

__END__

=head1 NAME

Onyphe::Apic - ONYPHE API Common routines

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE E<lt>contact_at_onyphe.ioE<gt>

=cut
