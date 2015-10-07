use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Path::IsDev::Heuristic::MYMETA;

our $VERSION = '1.001002';

# ABSTRACT: Determine if a path contains MYMETA.(json|yml)

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY
















use Role::Tiny::With qw( with );
with 'Path::IsDev::Role::Heuristic', 'Path::IsDev::Role::Matcher::Child::Exists::Any::File';










sub files {
  return qw( MYMETA.json MYMETA.yml );
}







sub matches {
  my ( $self, $result_object ) = @_;
  if ( $self->child_exists_any_file( $result_object, $self->files ) ) {
    $result_object->result(1);
    return 1;
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::IsDev::Heuristic::MYMETA - Determine if a path contains MYMETA.(json|yml)

=head1 VERSION

version 1.001002

=head1 DESCRIPTION

This heuristic is intended as a guarantee that B<SOME> kind of top level marker will
be present in a distribution, as all the main tool-chains emit this file during C<configure>.

Granted, this heuristic is expected to be B<never> needed, as in order to create such a file, you first need a C<Build.PL>/C<Makefile.PL> to generate it.

=head1 METHODS

=head2 C<files>

Files relevant to this heuristic

    MYMETA.json
    MYMETA.yml

=head2 C<matches>

Matches if any of the files in C<files> exist as children of the C<path>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Path::IsDev::Heuristic::MYMETA",
    "interface":"single_class",
    "does":[
        "Path::IsDev::Role::Heuristic",
        "Path::IsDev::Role::Matcher::Child::Exists::Any::File"
    ]
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
