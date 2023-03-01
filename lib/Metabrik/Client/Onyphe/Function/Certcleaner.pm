#
# $Id$
#
# client::onyphe::function::certcleaner Brik
#
package Metabrik::Client::Onyphe::Function::Certcleaner;
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

sub process {
   my $self = shift;
   my ($flat, $state, $args, $output) = @_;

   my $parsed = $self->parse($args);
   my $domaincount = (defined($parsed->{domaincount}) && $parsed->{domaincount}[0]) || 20;

   my $domain = $self->value($flat, 'domain');
   my $issuer_org = $self->value($flat, 'issuer.organization');
   my $subject_org = $self->value($flat, 'subject.organization');
   my $subject_commonname = $self->value($flat, 'subject.commonname');
   my $subject_altname = $self->value($flat, 'subject.altname');

   my $count_domain = defined($domain) ? @$domain : 0;
   my $subject_commonname_str = defined($subject_commonname)
      ? join(',', @$subject_commonname) : undef;
   my $subject_altname_str = defined($subject_altname)
      ? join(',', @$subject_altname) : undef;

   # netkin.io
   # sni.cloudflaressl.com

   if (! ($count_domain >= $domaincount)
   &&  ! (defined($issuer_org) && $issuer_org->[0] eq 'Cloudflare, Inc.')
   &&  ! (defined($issuer_org) && $issuer_org->[0] eq 'Amazon')
   &&  ! (defined($subject_org) && $subject_org->[0] eq 'SALESFORCE.COM, INC.')
   &&  ! (defined($subject_org) && $subject_org->[0] eq 'Microsoft Corporation')
   &&  ! (defined($subject_commonname_str) && $subject_commonname_str =~ m{salesforce-communities})
   &&  ! (defined($subject_commonname_str) && $subject_commonname_str =~ m{^tls\.automattic\.com})
   &&  ! (defined($subject_commonname_str) && $subject_commonname_str =~ m{^imperva\.com$})
   &&  ! (defined($subject_commonname_str) && $subject_commonname_str =~ m{^wedia-group\.com$})
   &&  ! (defined($subject_altname_str) && $subject_altname_str =~ m{cloudapp\.azure\.com})
   ) {
      push @$output, $flat;
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function::Certcleaner - client::onyphe::function::certcleaner Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
