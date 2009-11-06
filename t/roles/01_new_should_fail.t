use Test::More tests => 1;

{
    package Breakable;
    use Coat::Role;
    1;
}

eval { Breakable->new };
like $@, qr/a Role cannot be instanciated/, 'cannot create instance from a role';

