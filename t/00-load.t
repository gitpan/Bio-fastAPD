#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'fastAPD' ) || print "Bail out!\n";
}

diag( "Testing fastAPD $fastAPD::VERSION, Perl $], $^X" );
