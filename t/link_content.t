#!perl -T

use strict;
use warnings;
use Test::More tests => 8;
use Test::Builder::Tester;
use URI::file;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $mech=Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get(URI::file->cwd().'t/goodlinks.html');
my @urls=$mech->links();

# test regex
test_out('not ok 1 - link_content_like'); 
test_err("#     Failed test ($0 at line ".line_num(+2).")");
test_diag("     'blah' doesn't look much like a regex to me.");
$mech->link_content_like(\@urls,'blah','Testing the regex');
test_test('Handles bad regexs');

# like
test_out('ok 1 - Checking all page links contain: Test');
$mech->link_content_like(\@urls,qr/Test/,'Checking all page links contain: Test');
test_test('Handles All page links contents successful');

test_out('not ok 1 - Checking all page link content failures');
test_err("#     Failed test ($0 at line ".line_num(+4).")");
test_diag('goodlinks.html');
test_diag('badlinks.html');
test_diag('goodlinks.html');
$mech->link_content_like(\@urls,qr/BadTest/,'Checking all page link content failures');
test_test('Handles link content not found');

# unlike
# test regex
test_out('not ok 1 - link_content_unlike'); 
test_err("#     Failed test ($0 at line ".line_num(+2).")");
test_diag("     'blah' doesn't look much like a regex to me.");
$mech->link_content_unlike(\@urls,'blah','Testing the regex');
test_test('Handles bad regexs');

test_out('ok 1 - Checking all page links do not contain: BadTest');
$mech->link_content_unlike(\@urls,qr/BadTest/,'Checking all page links do not contain: BadTest');
test_test('Handles All page links unlike contents successful');

test_out('not ok 1 - Checking all page link unlike content failures');
test_err("#     Failed test ($0 at line ".line_num(+4).")");
test_diag('goodlinks.html');
test_diag('badlinks.html');
test_diag('goodlinks.html');
$mech->link_content_unlike(\@urls,qr/Test/,'Checking all page link unlike content failures');
test_test('Handles link unlike content found');
