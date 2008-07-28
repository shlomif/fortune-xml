#!perl -T

use Test::More tests => 2;

BEGIN {
    # TEST
	use_ok( 'XML::Grammar::Fortune::Synd' );
    # TEST
	use_ok( 'XML::Grammar::Fortune::Synd::Heap::Elem' );
}

diag( "Testing XML::Grammar::Fortune::Synd $XML::Grammar::Fortune::Synd::VERSION, Perl $], $^X" );
