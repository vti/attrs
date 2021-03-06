# Perl attributes

When I need attributes in Perl, I don't need accessors or mutators, I actually
need this:

```
package Foo;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{score} = delete $params{score} or die 'score required';
    $self->{page}  = delete $params{page} || 1;

    die 'unknown parameters' if %params;

    return $self;
}
```

I want this to be simplified, clear, correctly work with inheritance, being able
to overwrite super arguments or initialization phase.

Hence `attrs`!

```
package Foo;
use attrs 'score!', page => sub { 1 };

package SomeOtherClass;
use base 'Foo';

sub page { $_[0]->{page} }

package main;

my $page = SomeOtherClass->new(score => 5)->page;
```
