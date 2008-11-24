use Test::More 'no_plan';

{ 
    package Calculator;
    use Coat;
    use Coat::Types;

    subtype 'Float' 
        => as 'Num'
        => where { /^-?\d+\.\d+$/ };

    coerce 'Float'
        => from 'Int'
        => via { $_[0].".0" };

    has float => (isa => 'Float', coerce => 1); 
}

my $cal = new Calculator;
ok( $cal->float(1.2), '1.2 is accepted as a float' );
ok( $cal->float eq '1.2', '$cal->float == 1.2');

ok( $cal->float(2), '2 is accepted as a float' );
ok( $cal->float eq '2.0', '$cal->float == 2.0 (has been coerced)');


