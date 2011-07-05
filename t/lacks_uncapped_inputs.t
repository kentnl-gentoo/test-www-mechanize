#!perl -Tw

use strict;
use warnings;
use Test::More tests => 6;
use Test::Builder::Tester;

use URI::file;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $mech = Test::WWW::Mechanize->new();
isa_ok( $mech,'Test::WWW::Mechanize' );

GOOD: {
    my $uri = URI::file->new_abs( 't/lacks_uncapped_inputs-good.html' )->as_string;
    $mech->get_ok( $uri ) or die;

    test_out( 'ok 1 - This should have no failures' );
    $mech->lacks_uncapped_inputs( 'This should have no failures' );
    test_test( 'Finds the lacks' );
}

BAD: {
    my $uri = URI::file->new_abs( 't/lacks_uncapped_inputs-bad.html' )->as_string;
    $mech->get_ok( $uri ) or die;

    test_out( 'not ok 1 - This should have three errors found' );
    test_fail( +6 );
    test_diag( q{         got: 3} );
    test_diag( q{    expected: 0} );
    test_diag( q{foo has no maxlength attribute} );
    test_diag( q{quux has an invalid maxlength attribute of "dogs"} );
    test_diag( q{crunchy has an invalid maxlength attribute of "-1"} );
    $mech->lacks_uncapped_inputs( 'This should have three errors found' );
    test_test( 'Detect uncapped' );
}

done_testing();
