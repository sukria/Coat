use Test::More 'no_plan';
use strict;
use warnings;

{
    package NumberFactory;
    use Coat;
    use Coat::Types;

    type 'Natural' 
        => where { $_ > 0 }
        => message { "$_ is not a Natural number" };

    type 'Float'   => where { /^\d+\.\d+$/ };

    subtype 'Month'
        => as 'Natural'
        => where { $_ <= 12 }
        => message { "$_ is not a month" };

    subtype 'WinterMonth'
        => as 'Month'
        => where { $_ >= 10 }
        => message { "$_ is not a month of winter" };

    enum Colour => 'Red', 'Green', 'Blue';

    has n => (isa => 'Natural');
    has f => (isa => 'Float');
    has month => (isa => 'Month');
    has winter => (isa => 'WinterMonth');
    has col => (isa => 'Colour');
}

my $factory = new NumberFactory;

# Natural
eval { $factory->n(0) };
ok($@ =~ /0 is not a Natural number/, 
   "unable to set an null integer as a Natural");
ok ($factory->n(24), '24 accepted as a Natural' );

# Float
eval { $factory->f(2) };
ok($@, "unable to set 2 as a Float");
ok ($factory->n(2.0), '2.0 accepted as a Float' );

# Month (subtype of Natural)
eval { $factory->month(0) };
ok($@, "unable to set 14 as a Month ");
eval { $factory->month(14) };
ok($@, "unable to set 14 as a Month ");
ok ($factory->month(12), '12 is a valid Month' );

# WinterMonth (subtype of Month)
eval { $factory->winter(0) };
ok($@, "unable to set 0 as a WinterMonth ");
eval { $factory->winter(14) };
ok($@, "unable to set 14 as a Month");
eval { $factory->winter(3) };
ok($@, "unable to set 8 as a WinterMonth");
ok ($factory->winter(12), '12 is a valid WinterMonth' );

ok( $factory->col('Red'), 'Red is a valid Colour' );
eval { $factory->col('Yellow') };
ok($@, "Yellow is not a valid colour " );
