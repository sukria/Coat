use strict;
use warnings;

{
    package One;
	use Coat;
	has 'one' => (isa => 'Int', is => 'rw', default => 1);
	
	package Two;
	use Coat;
	extends 'One';
	has 'two' => (isa => 'Int', is => 'rw', default => 2);
	
	package Three;
	use Coat;
	extends 'Two';
	has 'three' => (isa => 'Int', is => 'rw', default => 3);
	
	package Four;
	use Coat;
	extends 'Three';
	has 'four' => (isa => 'Int', is => 'rw', default => 4);
}

use Test::More tests => 4;

my $four = Four->new;

is($four->four, 4, 'Level 4 return 4');
is($four->three, 3, 'Level 3 return 3');
is($four->two, 2, 'Level 2 return 2');
is($four->one, 1, 'Level 1 return 1');
