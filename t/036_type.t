use Test::More 'no_plan';

use strict;
use warnings;


{
	package A;
	use Coat;
	has 'a'	=> (is =>'rw', isa => 'A');
	
	package B;
	use Coat;
	
	extends 'A';
	has 'b'			=> (is => 'rw', isa => 'B');

	package C;
	use Coat;
	
	extends 'B';
	has 'c'			=> (is => 'rw', isa => 'C');
}


# OBJET A
my $a = A->new();

# Methode a
eval {
	$a->a(A->new());
};
ok(!$@,'$a->a(A->new()) ok');

eval {
	$a->a(B->new());
};
is($@, '', '$a->a(B->new()) ok');
eval {
	$a->a(C->new());
};
ok(!$@,'$a->a(C->new()) ok');


# OBJET B
my $b = B->new();

# Methode a
eval {
	$b->a(A->new());
};
ok(!$@,'$b->a(A->new()) ok');
eval {
	$b->a(B->new());
};
ok(!$@,'$b->a(B->new()) ok');
eval {
	$b->a(C->new());
};
ok(!$@,'$b->a(C->new()) ok');

# Methode b
eval {
	$b->b(A->new());
};
ok($@,'$b->b(A->new()) not valide');
eval {
	$b->b(B->new());
};
ok(!$@,'$b->a(B->new()) ok');
eval {
	$b->b(C->new());
};
ok(!$@,'$b->a(C->new()) ok');

# OBJET C
my $c = C->new();

# Methode a
eval {
	$c->a(A->new());
};
ok(!$@,'$c->a(A->new()) ok');
eval {
	$c->a(B->new());
};
ok(!$@,'$c->a(B->new()) ok');
eval {
	$c->a(C->new());
};
ok(!$@,'$c->a(C->new()) ok');

# Methode b
eval {
	$c->b(A->new());
};
ok($@,'$c->b(A->new()) not valide');
eval {
	$c->b(B->new());
};
ok(!$@,'$c->b(B->new()) ok');
eval {
	$c->b(C->new());
};
ok(!$@,'$c->b(C->new()) ok');

# Methode c
eval {
	$c->c(A->new());
};
ok($@,'$c->c(A->new()) not valide');
eval {
	$c->c(B->new());
};
ok($@,'$c->c(B->new()) not valide');
eval {
	$c->c(C->new());
};
ok(!$@,'$c->c(C->new()) ok');

1;
