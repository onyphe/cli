#
# $Id$
#
package Metabrik::Client::Onyphe::Function;
use strict;
use warnings;

our $VERSION = '3.03';

use base qw(Metabrik::Client::Onyphe);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(client onyphe) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         nested => [ qw(fields) ],
         last => [ qw(0|1) ],
         no_unflatten => [ qw(0|1) ],
      },
      attributes_default => {
         nested => [ qw(app.http.component app.http.header alert) ],
         last => 0,
         no_unflatten => 0,
      },
      commands => {
         is_nested => [ qw(field) ],
         value => [ qw(flat field) ],
         fields => [ qw(flat field) ],
         delete => [ qw(flat field) ],
         clone => [ qw(doc) ],
         flatten => [ qw(doc) ],
         unflatten => [ qw(flat) ],
         iter => [ qw(page callback) ],
         return => [ qw(page new state|OPTIONAL) ],
         parse => [ qw(arguments) ],
      },
      require_modules => {
         'Data::Dumper' => [ ],
         'Text::ParseWords' => [ ],
         'Storable' => [ qw(dclone) ],
      },
   };
}

#
# Check given field is of nested kind:
#
# $self->is_nested("domain");                      # 0
# $self->is_nested("app.http.component");          # ( 'app.http.component', undef )
# $self->is_nested("app.http.component.product");  # ( 'app.http.component', 'product' )
#
sub is_nested {
   my $self = shift;
   my ($field) = @_;

   $self->brik_help_run_undef_arg('is_nested', $field) or return;

   my $nested = { map { $_ => 1 } @{$self->nested} };

   my ($head, $leaf) = $field =~ m{^(.+)\.(\S+)$};
   #$self->log->info("nested: field [$field] head [$head] leaf [$leaf]");

   my $is_nested = 0;
   # Handle first case: app.http.component.product given as input:
   # Will have head set to app.http.component and leaf to product:
   if (defined($head) && $nested->{$head}) {
      $is_nested = 1;
   }
   # Handle second case: app.http.component given as input:
   elsif ($nested->{$field}) {
      $head = $field;
      $leaf = undef;
      $is_nested = 1;
   }

   return $is_nested ? [ $head, $leaf ] : 0;
}

#
# Always return values as ARRAY, undef when no value found:
#
sub value {
   my $self = shift;
   my ($flat, $field) = @_;

   $self->brik_help_run_undef_arg('value', $flat) or return;
   $self->brik_help_run_undef_arg('value', $field) or return;

   my @value = ();

   # Handle nested fields:
   if (my $split = $self->is_nested($field)) {
      my $root = $split->[0];
      my $leaf = $split->[1];
      if (defined($leaf)) {
         for (@{$flat->{$root}}) {
            if (defined($_->{$leaf})) {
               my $ary = ref($_->{$leaf}) ? $_->{$leaf} : [ $_->{$leaf} ];
               push @value, @$ary;
            }
         }
      }
   }
   # Handle standard fields:
   else {
      if (defined($flat->{$field})) {
         my $ary = ref($flat->{$field}) eq 'ARRAY' ? $flat->{$field} : [ $flat->{$field} ];
         push @value, @$ary;
      }
   }

   return @value ? \@value : undef;
}

sub fields {
   my $self = shift;
   my ($flat) = @_;

   $self->brik_help_run_undef_arg('fields', $flat) or return;

   my @fields = ();

   my $flat_fields = [ map { $_ } keys %$flat ];
   for my $field (@$flat_fields) {
      if ($self->is_nested($field)) {
         my $ary = ref($flat->{$field}) eq 'ARRAY' ? $flat->{$field} : [ $flat->{$field} ];
         for (@$ary) {
            for my $leaf (keys %$_) {
               push @fields, "$field.$leaf";
            }
         }
      }
      else {
         push @fields, $field;
      }
   }

   return \@fields;
}

sub values {
   my $self = shift;
   my ($flat) = @_;

   $self->brik_help_run_undef_arg('values', $flat) or return;

   my @values = ();
   my $fields = $self->fields($flat);

   for (@$fields) {
      push @values, $flat->{$_};
   }

   return \@values;
}

sub dumper {
   my $self = shift;
   my ($arg) = @_;

   $self->brik_help_run_undef_arg('dumper', $arg) or return;

   return Data::Dumper::Dumper($arg)."\n";
}

#
# $self->delete($flat, "domain");
# $self->delete($flat, "app.http.component");
# $self->delete($flat, "app.http.component.product");
#
sub delete {
   my $self = shift;
   my ($flat, $field) = @_;

   $self->brik_help_run_undef_arg('delete', $flat) or return;
   $self->brik_help_run_undef_arg('delete', $field) or return;

   # Handle nested fields:
   if (my $split = $self->is_nested($field)) {
      my $root = $split->[0];
      my $leaf = $split->[1];
      # Delete at the leaf level:
      if (defined($leaf)) {
         my @keep = ();
         for my $this (@{$flat->{$root}}) {
            delete $this->{$leaf};
            push @keep, $this if keys %$this;  # Keep the final object only when not empty
         }
         # Keep the final array only when not empty
         if (@keep > 0) {
            $flat->{$root} = \@keep;
         }
         # And when empty, completly remove the root field:
         else {
            delete $flat->{$root};
         }
      }
      # Or the complete root field when asked for:
      else {
         delete $flat->{$root};
      }
   }
   # Handle standard fields:
   else {
      delete $flat->{$field};
   }

   return $flat;
}

#
# Clone given doc so we can duplicate it and modify on a new one:
#
sub clone {
   my $self = shift;
   my ($doc) = @_;

   $self->brik_help_run_undef_arg('clone', $doc) or return;

   return Storable::dclone($doc);
}

#
# Flatten given doc so we can work with field names easily like a.b.c instead of {a}{b}{c}:
#
sub flatten {
   my $self = shift;
   my ($docs) = @_;

   $self->brik_help_run_undef_arg('flatten', $docs) or return;

   $docs = ref($docs) eq 'ARRAY' ? $docs : [ $docs ];

   my @new = ();
   for my $doc (@$docs) {
      my $new = {};
      my $sub; $sub = sub {
         my ($doc, $field) = @_;

         for my $k (keys %$doc) {
            my $this_field = defined($field) ? "$field.$k" : $k;
            if (ref($doc->{$k}) eq 'HASH') {
               $sub->($doc->{$k}, $this_field);
            }
            else {
               $new->{$this_field} = $doc->{$k};
            }
         }

         return $new;
      };
      push @new, $sub->($doc);
   }

   return \@new;
}

sub unflatten {
   my $self = shift;
   my ($flats) = @_;

   $self->brik_help_run_undef_arg('unflatten', $flats) or return;

   $flats = ref($flats) eq 'ARRAY' ? $flats : [ $flats ];

   my @new = ();
   for my $flat (@$flats) {
      my $new = {};

      for my $k (keys %$flat) {
         my @toks = split(/\./, $k);
         my $value = $flat->{$k};

         my $current = $new;
         my $last = $#toks;
         for my $idx (0..$#toks) {
            if ($idx == $last) {  # Last token
               $current->{$toks[$idx]} = $value;
               last;
            }

            # Create HASH key so we can iterate and create all subkeys
            # Merge with existing or create empty HASH:
            $current->{$toks[$idx]} = $current->{$toks[$idx]} || {};
            $current = $current->{$toks[$idx]};
         }
      }

      push @new, $new;
   }

   return \@new;
}

# Will iterate over all object results. Output of functions will create a new ARRAY
# of objects, maybe modified by some pipeline functions.
sub iter {
   my $self = shift;
   my ($page, $cb, $state, @args) = @_;

   my @new = ();

   for my $this (@{$page->{results}}) {
      # If callback returns undef, we consider it a fatal error, we abort.
      $cb->($this, $state, \@new, @args) or return;
   }

   return $self->return($page, \@new);
}

sub run {
   my $self = shift;
   my ($page, $state, $args) = @_;

   # Put in flat format to make it easier to use in functions:
   my $flats = $self->flatten($page->{results});

   my @output = ();
   for my $flat (@$flats) {
      $self->process($flat, $state, $args, \@output);
   }

   # Put back in doc format so we can display on STDOUT in original format,
   # except when not wanted:
   my $output = \@output;
   $output = $self->unflatten(\@output) unless $self->no_unflatten;

   return $self->return($page, $output);
}

sub return {
   my $self = shift;
   my ($page, $new, $state) = @_;

   $self->brik_help_run_undef_arg('return', $new) or return;
   $self->brik_help_run_invalid_arg('return', $new, 'ARRAY') or return;

   return {
      %$page,                 # Get defaults results, then overwrite some
      count => scalar(@$new), # Overwrite with new docs count
      results => $new,        # Overwrite with new docs ARRAY
      state => $state,
   };
}

sub placeholder {
   my $self = shift;
   my ($query, $flat) = @_;

   # Copy original to not modify it:
   my $copy = $query;
   my (@holders) = $query =~ m{[\w\.]+\s*:\s*\$([\w\.]+)}g;

   # Update search clause with placeholder values
   my %searches = ();
   for my $holder (@holders) {
      my $values = $self->value($flat, $holder);
      for my $value (@$values) {
         while ($copy =~ s{(\S+)\s*:\s*\$$holder}{$1:$value}) { }
         $searches{$copy}++;  # Make them unique
      }
   }

   return [ keys %searches ];
}

#
# Will return $arg parsed as usable arguments and also original $arg value:
#
sub parse {
   my $self = shift;
   my ($args) = @_;

   my @a = Text::ParseWords::quotewords('\s+', 0, $args);

   my $parsed = {};
   my $idx = 0;
   for (@a) {
      my ($k, $v) = split(/\s*=\s*/, $_);
      if (defined($k) && defined($v)) {
         $parsed->{$k} = [ sort { $a cmp $b } split(/\s*,\s*/, $v) ];
      }
      elsif (defined($k)) {
         $parsed->{$idx++} = $k;
      }
   }

   return $parsed;
}

1;

__END__

=head1 NAME

Metabrik::Client::Onyphe::Function - client::onyphe::function Brik

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DEVELOPMENT

If you want to write your function, you just need to write the process() method. It reveives as input the matched document, its flat version and its JSON string version. You can process the document at your will, but you have to write it as output in document format for further processing in the pipeline. The flat view is only an internal reprensentation with the aim of making it easier to interface with the command line and the ONYPHE Processing Language.

In the case your process() method does not write anything to output argument, you will just skip matched document.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
