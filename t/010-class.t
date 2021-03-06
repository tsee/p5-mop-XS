#!/usr/bin/env perl

use v5.18;
use warnings;

use Test::More;
use Data::Dumper qw[ Dumper ];
use Devel::Peek;

BEGIN {
    use_ok('mop')
};

package Foo::Bar::Baz 0.01 {
    sub test {  __PACKAGE__ . '::test' }
}

{
    my $mcv = mop::internals::newMopMcV("Foo::Bar::Baz");

    is(mop::internals::MopMcV::name($mcv), 'Foo::Bar::Baz', '... got the right name');
    is(mop::internals::MopMcV::version($mcv), '0.01', '... got the right version');
    is(mop::internals::MopMcV::authority($mcv), undef, '... got the right authority');

    is(mop::internals::MopMcV::superclass($mcv), undef, '... got the right superclass');

    ok(mop::internals::MopMcV::has_method($mcv, 'test'), '... we have the &test method');
    ok(!mop::internals::MopMcV::has_method($mcv, 'fail'), '... we do not have the &fail method');

    {
        my $test = mop::internals::MopMcV::get_method($mcv, 'test');
        is(ref($test), 'CODE', '... got a code ref');
        is(mop::internals::MopMmV::name($test), 'test', '... got the right name');
        is(mop::internals::MopMmV::associated_class($test), $mcv, '... got the right stash');

        is($test->(), 'Foo::Bar::Baz::test', '... got the right value');

        my ($before, $after) = (0, 0);
        mop::internals::MopOV::bind_event($test, 'before:EXECUTE', sub { $before++ });
        mop::internals::MopOV::bind_event($test, 'after:EXECUTE', sub { $after++ });

        is($test->(), 'Foo::Bar::Baz::test', '... got the right value');
        is($before, 1, '... our before:EXECUTE event fired');
        is($after, 1, '... our after:EXECUTE event fired');

        # call method ...
        my $baz = mop::internals::MopMcV::construct_instance($mcv, \(my $x));

        isa_ok($baz, 'Foo::Bar::Baz');
        can_ok($baz, 'test');

        is($baz->test, 'Foo::Bar::Baz::test', '... got the right value');
        is($before, 2, '... our before:EXECUTE event fired');
        is($after, 2, '... our after:EXECUTE event fired');

        is($test->(), 'Foo::Bar::Baz::test', '... got the right value');
        is($before, 3, '... our before:EXECUTE event fired');
        is($after, 3, '... our after:EXECUTE event fired');

        is($baz->test, 'Foo::Bar::Baz::test', '... got the right value');
        is($before, 4, '... our before:EXECUTE event fired');
        is($after, 4, '... our after:EXECUTE event fired');
    }

    is(mop::internals::MopMcV::get_method($mcv, 'fail'), undef, '... nothing back from getting the &fail method');
=pod
    mop::internals::MopMcV::add_method($mcv, 'testing', sub {
        'Foo::Bar::Baz::testing'
    });

    {
        my $testing = mop::internals::MopMcV::get_method($mcv, 'testing');
        is(ref($testing), 'CODE', '... got a code ref');
        is(mop::internals::MopMmV::name($testing), 'testing', '... got the right name');
        is(mop::internals::MopMmV::associated_class($testing), $mcv, '... got the right stash');

        is($testing->(), 'Foo::Bar::Baz::testing', '... got the right value');
    }
=cut
    my $baz = mop::internals::MopMcV::construct_instance($mcv, \(my $x));

    isa_ok($baz, 'Foo::Bar::Baz');
    can_ok($baz, 'test');
#    can_ok($baz, 'testing');

    is($baz->test, 'Foo::Bar::Baz::test', '... got the right value');
#    is($baz->testing, 'Foo::Bar::Baz::testing', '... got the right value');
}

package Foo::Bar {
    our $VERSION   = '0.02';
    our $AUTHORITY = 'cpan:STEVAN';
    our @ISA = ('Foo::Bar::Baz');
    sub test { __PACKAGE__ . '::test' }
}

{
    my $mcv = mop::internals::newMopMcV("Foo::Bar");

    mop::internals::MopOV::set_at_slot($mcv, "$!test", 10);

    is(mop::internals::MopOV::get_at_slot($mcv, "$!test"), 10, '... got the value stored in magic');

    is(mop::internals::MopMcV::name($mcv), 'Foo::Bar', '... got the right name');
    is(mop::internals::MopMcV::version($mcv), '0.02', '... got the right version');
    is(mop::internals::MopMcV::authority($mcv), 'cpan:STEVAN', '... got the right authority');

    my $super = mop::internals::MopMcV::superclass($mcv);
    is(ref($super), 'HASH', '... this is the glob ref we expected');

    is(mop::internals::MopMcV::name($super), 'Foo::Bar::Baz', '... got the right superclass');
    is(mop::internals::MopMcV::version($super), '0.01', '... got the right version');

    ok(mop::internals::MopMcV::has_method($mcv, 'test'), '... we have the &test method');
    ok(!mop::internals::MopMcV::has_method($mcv, 'fail'), '... we do not have the &fail method');

    {
        my $test = mop::internals::MopMcV::get_method($mcv, 'test');
        is(ref($test), 'CODE', '... got a code ref');

        is($test->(), 'Foo::Bar::test', '... got the right value');
    }

    my $bar = mop::internals::MopMcV::construct_instance($mcv, \(my $x));

    isa_ok($bar, 'Foo::Bar');
    isa_ok($bar, 'Foo::Bar::Baz');
    can_ok($bar, 'test');
#    can_ok($bar, 'testing');    

    is($bar->test, 'Foo::Bar::test', '... got the right value');
#    is($bar->testing, 'Foo::Bar::Baz::testing', '... got the right value');
}

# works on as yet to be created packages ...
{
    my $mcv = mop::internals::newMopMcV("Foo::Baz");

    is(mop::internals::MopMcV::name($mcv), 'Foo::Baz', '... got the right name');
    is(mop::internals::MopMcV::version($mcv), undef, '... got the right version');
    is(mop::internals::MopMcV::authority($mcv), undef, '... got the right authority');

    mop::internals::MopMcV::set_superclass($mcv, \%Foo::Bar::);

    my $super = mop::internals::MopMcV::superclass($mcv);
    is(ref($super), 'HASH', '... this is the glob ref we expected');

    is(mop::internals::MopMcV::name($super), 'Foo::Bar', '... got the right superclass');
    is(mop::internals::MopMcV::version($super), '0.02', '... got the right version');
    is(mop::internals::MopMcV::authority($super), 'cpan:STEVAN', '... got the right authority');


    my $baz = mop::internals::MopMcV::construct_instance($mcv, \(my $x));

    isa_ok($baz, 'Foo::Baz');
    isa_ok($baz, 'Foo::Bar');
    isa_ok($baz, 'Foo::Bar::Baz');
    can_ok($baz, 'test');

    is($baz->test, 'Foo::Bar::test', '... got the right value');
}

# and the magic persists
{
    my $mcv = \%Foo::Bar::;

    is(mop::internals::MopOV::get_at_slot($mcv, "$!test"), 10, '... got the (persisted) value stored in magic');

    is(mop::internals::MopMcV::name($mcv), 'Foo::Bar', '... got the right name');
    is(mop::internals::MopMcV::version($mcv), '0.02', '... got the right version');
    is(mop::internals::MopMcV::authority($mcv), 'cpan:STEVAN', '... got the right authority');
}

package My::ImportTest {
    use Data::Dumper qw[ Dumper ];
    sub test { __PACKAGE__ . '::test' }
}

{
    my $mcv = mop::internals::newMopMcV("My::ImportTest");

    ok(mop::internals::MopMcV::has_method($mcv, 'test'), '... we have the &test method');
    ok(!mop::internals::MopMcV::has_method($mcv, 'Dumper'), '... we do not have the imported &Dumper function');

    {
        my $test = mop::internals::MopMcV::get_method($mcv, 'test');
        is(ref($test), 'CODE', '... got a code ref');

        is($test->(), 'My::ImportTest::test', '... got the right value');
    }

    is(mop::internals::MopMcV::get_method($mcv, 'Dumper'), undef, '... nothing back from getting the &Dumper function');
}


done_testing;