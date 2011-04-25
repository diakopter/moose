package Moose::Error::Default;

use strict;
use warnings;

use Carp::Heavy;
use Class::MOP::MiniTrait;

use base 'Class::MOP::Object';

Class::MOP::MiniTrait::apply(__PACKAGE__, 'Moose::Meta::Object::Trait');

sub new {
    my ( $self, @args ) = @_;
    if (defined $ENV{MOOSE_ERROR_STYLE} && $ENV{MOOSE_ERROR_STYLE} eq 'croak') {
        $self->create_error_croak( @args );
    }
    else {
        $self->create_error_confess( @args );
    }
}

sub _inline_new {
    my ( $self, @args ) = @_;

    return '(do { '
             . '(defined $ENV{MOOSE_ERROR_STYLE} && $ENV{MOOSE_ERROR_STYLE} eq "croak"'
               . ' ? ' . $self->_inline_create_error_carpmess(@args)
               . ' : ' . $self->_inline_create_error_carpmess(@args, longmess => 1)
         . ')})';
}

sub create_error_croak {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args );
}

sub create_error_confess {
    my ( $self, @args ) = @_;
    $self->_create_error_carpmess( @args, longmess => 1 );
}

sub _create_error_carpmess {
    my ( $self, %args ) = @_;

    my $carp_level = 3 + ( $args{depth} || 1 );
    local $Carp::MaxArgNums = 20; # default is 8, usually we use named args which gets messier though

    my @args = exists $args{message} ? $args{message} : ();

    if ( $args{longmess} || $Carp::Verbose ) {
        local $Carp::CarpLevel = ( $Carp::CarpLevel || 0 ) + $carp_level;
        return Carp::longmess(@args);
    } else {
        return Carp::ret_summary($carp_level, @args);
    }
}

sub _inline_create_error_carpmess {
    my ( $self, %args ) = @_;

    my $carp_level = $args{depth} || 0;

    my $create_message = 'Carp::longmess(' . $args{message} . ')';

    if (!$args{longmess}) {
        $create_message =
            '($Carp::Verbose '
              . '? ' . $create_message . ' '
              . ': Carp::ret_summary('
                  . $carp_level . ', ' . $args{message}
              . '))';
    }

    return
        '(do { '
          . 'local $Carp::MaxArgNums = 20; '
          . 'local $Carp::CarpLevel = ($Carp::CarpLevel || 0) + '
              . $carp_level . '; '
          . $create_message
      . '})';
}

1;

# ABSTRACT: L<Carp> based error generation for Moose.

__END__

=pod

=head1 DESCRIPTION

This class implements L<Carp> based error generation.

The default behavior is like L<Moose::Error::Confess>. To override this to
default to L<Moose::Error::Croak>'s behaviour on a system wide basis, set the
MOOSE_ERROR_STYLE environment variable to C<croak>. The use of this
environment variable is considered experimental, and may change in a future
release.

=head1 METHODS

=over 4

=item B<< Moose::Error::Default->new(@args) >>

Create a new error. Delegates to C<create_error_confess> or
C<create_error_croak>.

=item B<< $error->create_error_confess(@args) >>

=item B<< $error->create_error_croak(@args) >>

Creates a new errors string of the specified style.

=back

=cut


