use strict;
use warnings;

use Test::More;
use Test::Fatal;

subtest 'throws on required element' => sub {
    {

        package Required;
        use attrs 'foo';
    }

    like exception { Required->new }, qr/foo required/;
};

subtest 'throws on unknown element' => sub {
    {

        package Unknown;
        use attrs;
    }

    like exception { Unknown->new(unknown => 'bar') },
      qr/unknown attribute unknown/;
};

subtest 'adds new attrs' => sub {
    {

        package Base2;
        use attrs 'foo';

        package Child2;
        use base 'Base2';
        use attrs 'bar';
    }

    like exception { Child2->new }, qr/bar required/;
};

subtest 'default values' => sub {
    {

        package Default;
        use attrs foo => sub { 1 };
    }

    is(Default->new->{foo}, 1);
};

subtest 'default undef values' => sub {
    {

        package WithUndef;
        use attrs foo => undef;
    }

    ok(WithUndef->new);
};

subtest 'accessors' => sub {
    {

        package Accessors;
        use attrs 'foo?';
    }

    is(Accessors->new(foo => 1)->foo, 1);
};

subtest 'constructor inheritance' => sub {
    {

        package ConstructorBase;
        use attrs 'foo?';

        package ChildWithoutAttrs;
        use base 'ConstructorBase';
    }

    is(ChildWithoutAttrs->new(foo => 1)->foo, 1);
};

subtest 'accessors with inheritance' => sub {
    {

        package AccessorsBase;
        use attrs 'foo?';

        package Accessors2;
        use base 'AccessorsBase';
        use attrs 'bar?', 'foo?';
    }

    is(Accessors2->new(foo => 1, bar => 2)->foo, 1);
    is(Accessors2->new(foo => 1, bar => 2)->bar, 2);
};

subtest 'redefining accessors' => sub {
    {

        package Accessors3;
        use attrs 'foo?';

        sub foo { 'hi' }
    }

    is(Accessors3->new(foo => 1)->foo, 'hi');
};

subtest 'upgrading raw classes' => sub {
    {

        package RawBase;
        sub new { bless {hello => 'there'}, shift }

        package Upgraded;
        use base 'RawBase';
        use attrs 'bar';

        sub SUPER_CALL { shift->SUPER::new(@_) }
    }

    is(Upgraded->new(bar => 1)->{bar},   1);
    is(Upgraded->new(bar => 1)->{hello}, 'there');
};

subtest 'build args' => sub {
    {

        package WithBuildArgs;
        use attrs 'foo?';

        sub BUILD_ARGS {
            my $class = shift;
            my ($foo) = @_;

            return foo => $foo;
        }
    }

    like exception { WithBuildArgs->new }, qr/foo required/;
    is(WithBuildArgs->new(1)->foo, 1);
};

subtest 'build' => sub {
    {

        package WithBuild;
        use attrs;

        sub BUILD {
            my $self = shift;

            $self->{else} = 'bar';
        }
    }

    is(WithBuild->new->{else}, 'bar');
};

done_testing;
