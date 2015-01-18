package attrs;

use strict;
use warnings;
use mro;

use Carp qw(croak);

sub import {
    shift;
    my (@params) = @_;

    my $package = (caller)[0];

    my %attrs = ();
    for (my $i = 0; $i < @params; $i++) {
        my $value = {required => 1};

        my $key = $params[$i];
        if ($key =~ s{\?$}{}) {
            $value->{accessor} = 1;
        }

        if (@params > $i + 1) {
            if (ref $params[$i + 1] eq 'CODE') {
                $value->{required} = 0;
                $value->{default}  = $params[$i + 1];
                $i++;
            }
            elsif (!defined $params[$i + 1]) {
                $value->{required} = 0;
                $value->{default} = sub { undef };
                $i++;
            }
        }

        $attrs{$key} = $value;
    }

    no strict 'refs';

    ${"$package\::_ATTRS"} = {%attrs};

    *{"$package\::new"} = sub {
        my $class = shift;

        my (%params) = $class->can('BUILD_ARGS') ? $class->BUILD_ARGS(@_) : @_;

        my $attrs = {};

        my $parents = mro::get_linear_isa($class);
        foreach my $parent (@$parents) {
            if ($attrs = ${"$parent\::_ATTRS"}) {
                last;
            }
        }

        foreach my $key (sort keys %params) {
            croak "unknown attribute $key"
              unless exists $attrs->{$key};
        }

        my $self;
        if (@$parents > 1 && $class->can('SUPER_CALL')) {
            $self = $class->SUPER_CALL(%params);
        }
        else {
            $self = {};
            bless $self, $class;
        }

        foreach my $attr (sort keys %$attrs) {
            my $is_required = $attrs->{$attr}->{required};
            my $default     = $attrs->{$attr}->{default};
            my $accessor    = $attrs->{$attr}->{accessor};

            croak "$attr required" if $is_required && !defined $params{$attr};

            my $value = $params{$attr};
            $value //= $default->($self) if $default;

            $self->{$attr} = $value;

            *{"$class\::$attr"} = sub { $_[0]->{$attr} }
              if $accessor && !$class->can($attr);
        }

        $self->BUILD if $self->can('BUILD');

        return $self;
    };
}

1;
