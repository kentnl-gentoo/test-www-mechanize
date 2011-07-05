#!perl -Tw

use strict;
use warnings;
use Test::More tests => 4;
use Test::Builder::Tester;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

use lib 't';
use TestServer;

my $server      = TestServer->new;
my $pid         = $server->background;
my $server_root = $server->root;

SUBMIT_GOOD_FORM: {
    my $mech = Test::WWW::Mechanize->new();
    isa_ok( $mech,'Test::WWW::Mechanize' );

    $mech->get_ok( "$server_root/form.html" );
    $mech->submit_form_ok( {form_number =>1}, 'Submit First Form' );
}

$server->stop;
