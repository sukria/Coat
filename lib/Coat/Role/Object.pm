package Coat::Role::Object;
use Carp 'confess';

sub new { confess "a Role cannot be instanciated" }

1;
