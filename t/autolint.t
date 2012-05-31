#!/usr/bin/env perl -T

use strict;
use warnings;
use Test::Builder::Tester;
use Test::More;
use URI::file;

use Test::WWW::Mechanize;

BEGIN {
    my $module = 'HTML::Lint 2.20';

    # Load HTML::Lint here for the imports
    if ( not eval "use $module; 1;" ) {
        plan skip_all => "$module is not installed, cannot test autolint";
    }
    plan tests => 27;
}


ACCESSOR_MUTATOR: {
    my $lint = HTML::Lint->new( only_types => HTML::Lint::Error::STRUCTURE );

    ACCESSOR: {
        my $mech = Test::WWW::Mechanize->new();
        ok( !$mech->autolint(), 'no autolint to new yields autolint off' );

        $mech = Test::WWW::Mechanize->new( autolint => undef );
        ok( !$mech->autolint(), 'undef to new yields autolint off' );

        $mech = Test::WWW::Mechanize->new( autolint => 0 );
        ok( !$mech->autolint(), '0 to new yields autolint off' );

        $mech = Test::WWW::Mechanize->new( autolint => 1 );
        ok( $mech->autolint(), '1 to new yields autolint on' );

        $mech = Test::WWW::Mechanize->new( autolint => [] );
        ok( $mech->autolint(), 'non-false, non-object to new yields autolint on' );

        $mech = Test::WWW::Mechanize->new( autolint => $lint );
        ok( $mech->autolint(), 'HTML::Lint object to new yields autolint on' );
    }

    MUTATOR: {
        my $mech = Test::WWW::Mechanize->new();

        ok( !$mech->autolint(0), '0 returns autolint off' );
        ok( !$mech->autolint(), '0 autolint really off' );

        ok( !$mech->autolint(''), '"" returns autolint off' );
        ok( !$mech->autolint(), '"" autolint really off' );

        ok( !$mech->autolint(1), '1 returns autolint off (prior state)' );
        ok( $mech->autolint(), '1 autolint really on' );

        ok( $mech->autolint($lint), 'HTML::Lint object returns autolint on (prior state)' );
        ok( $mech->autolint(), 'HTML::Lint object autolint really on' );
        my $ret = $mech->autolint( 0 );
        isa_ok( $ret, 'HTML::Lint' );
        ok( !$mech->autolint(), 'autolint off after nuking HTML::Lint object' );
    }
}

FLUFFY_PAGE_HAS_ERRORS: {
    my $mech = Test::WWW::Mechanize->new( autolint => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/fluffy.html' )->as_string;

    test_out( "not ok 1 - GET $uri" );
    test_fail( +5 );
    test_err( "# HTML::Lint errors for $uri" );
    test_err( '#  (10:9) <img src="/foo.gif"> tag has no HEIGHT and WIDTH attributes' );
    test_err( '#  (10:9) <img src="/foo.gif"> does not have ALT text defined' );
    test_err( '# 2 errors on the page' );
    $mech->get_ok( $uri );
    test_test( 'Fluffy page should have fluffy errors' );
}

CUSTOM_LINTER_IGNORES_FLUFFY_ERRORS: {
    my $lint = HTML::Lint->new( only_types => HTML::Lint::Error::STRUCTURE );

    my $mech = Test::WWW::Mechanize->new( autolint => $lint );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/fluffy.html' )->as_string;
    $mech->get_ok( $uri, 'Fluffy page should not have errors' );

    # And if we go to another page, the autolint object has been reset.
    $mech->get_ok( $uri, 'Second pass at the fluffy page should not have errors, either' );
}

GOOD_GET_GOOD_HTML: {
    my $mech = Test::WWW::Mechanize->new( autolint => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/good.html' )->as_string;
    $mech->get_ok( $uri );

    test_out( "ok 1 - GET $uri" );
    $mech->get_ok( $uri, "GET $uri" );
    test_test( 'Good GET, good HTML' );
}

GOOD_GET_BAD_HTML: {
    my $mech = Test::WWW::Mechanize->new( autolint => 1 );
    isa_ok( $mech, 'Test::WWW::Mechanize' );

    my $uri = URI::file->new_abs( 't/bad.html' )->as_string;

    # Test via get_ok
    test_out( "not ok 1 - GET $uri" );
    test_fail( +6 );
    test_err( "# HTML::Lint errors for $uri" );
    test_err( '#  (7:9) Unknown attribute "hrex" for tag <a>' );
    test_err( '#  (8:33) </b> with no opening <b>' );
    test_err( '#  (9:5) <a> at (8:9) is never closed' );
    test_err( '# 3 errors on the page' );
    $mech->get_ok( $uri, "GET $uri" );
    test_test( 'get_ok complains about bad HTML' );

    # Test via follow_link_ok
    test_out( 'not ok 1 - Following link back to bad.html' );
    test_fail( +6 );
    test_err( "# HTML::Lint errors for $uri" );
    test_err( '#  (7:9) Unknown attribute "hrex" for tag <a>' );
    test_err( '#  (8:33) </b> with no opening <b>' );
    test_err( '#  (9:5) <a> at (8:9) is never closed' );
    test_err( '# 3 errors on the page' );
    $mech->follow_link_ok( { text => 'Back to bad' }, 'Following link back to bad.html' );
    test_test( 'follow_link_ok complains about bad HTML' );
}

done_testing();
