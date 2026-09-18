#
# $Id: Asm.pm,v 0523b31a10d5 2026/07/10 09:48:35 james $
#
package Onyphe::Api::Asm;
use strict;
use warnings;

our $VERSION = '4.20.1';

use experimental qw(signatures);

use base qw(Onyphe::Apic);

# NOTE: only useful for building local accessors:
#our @AS = qw();
#__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildIndices;

use Data::Dump qw(dump);

sub get_baseurl ($self) {
   my $global = $self->config->{''};
   my $baseurl = $global->{api_asm_endpoint};
   die("FATAL: api_asm_endpoint not configured in ~/.onyphe.ini\n") unless defined($baseurl);
   return $baseurl;
}

sub get_apikey ($self) {
   my $global = $self->config->{''};
   my $apikey = $global->{api_asm_key} || $self->apikey;
   die("FATAL: api_asm_key not configured in ~/.onyphe.ini\n") unless defined($apikey);
   return $apikey;
}

sub all ($self, $params = undef, $opp_cb = undef, $opl = undef) {
   my $ua = $self->ua;
   my $url = $self->url('/asm/inventory/all'.$self->params($params));
   my $apikey = $self->get_apikey;
   my $headers = $self->headers($apikey);

   my $get = $self->get($ua, $url, $headers);

   # XXX: check success

   if (defined($params) && $params->{full}) {
      print $get->res->body."\n";
      return 1;
   }

   my $json = $get->res->json;
   unless (defined($opp_cb)) {
      return $json;
   }

   if (defined($params) && $params->{count}) {
      my $total = defined($json->{total}) ? $json->{total} : 0;
      return $opp_cb->([{ total => $total }], $opl);
   }

   my $results = defined($json->{results}) ? $json->{results} : [];
   return $opp_cb->($results, $opl);
}

sub delall ($self, $params = undef, $opp_cb = undef, $opl = undef) {
   my $ua = $self->ua;
   my $url = $self->url('/asm/inventory/delall'.$self->params($params));
   my $apikey = $self->get_apikey;
   my $headers = $self->headers($apikey);

   my $post = $self->post($ua, $url, $headers);

   # XXX: check success

   my $json = $post->res->json;

   return defined($opp_cb) ? $opp_cb->($json) : $json;
}

sub addall ($self, $input, $params = undef, $opp_cb = undef, $opl = undef) {
   my $ua = $self->ua;
   my $url = $self->url('/asm/inventory/addall'.$self->params($params));
   my $apikey = $self->get_apikey;
   #my $headers = $self->headers($apikey, 'application/x-www-form-urlencoded; charset=utf-8');
   my $headers = $self->headers($apikey, 'application/x-www-form-urlencoded');

   my $content = $self->load_input($input);
   #$content = join(',', @$content);
   #print $content."\n";
   #print dump($content)."\n";
   my $data = '';
   for (@$content) {
      chomp;
      $data .= "$_\n";
   }
   chomp($data);
   #print $data."\n";
   my $post = $self->post_content($ua, $url, $headers, $data);
   if ($self->is_error($post)) {
      die("FATAL: addall: ".$post->res->error->{message}."\n");
   }

   # XXX: check success

   my $json = $post->res->json;
   #print dump($json)."\n";

   return defined($opp_cb) ? $opp_cb->($json) : $json;
}

1;

__END__

=head1 NAME

Onyphe::Api::Asm - ONYPHE ASM API

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ONYPHE E<lt>contact_at_onyphe.ioE<gt>

=cut
