#!perl -Tw

use strict;
use warnings;
use Test::More tests => 5;
use Test::Builder::Tester;
use URI::file;

use constant PORT => 13432;

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $server=TWMServer->new(PORT);
my $pid=$server->background;
ok($pid,'HTTP Server started') or die "Can't start the server";

sub cleanup { kill(9,$pid) };
$SIG{__DIE__}=\&cleanup;

my $mech=Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get('http://localhost:'.PORT.'/goodlinks.html');

# test regex
test_out( 'ok 1 - Does it say Mungo eats cheese?' );
$mech->content_lacks( 'Mungo eats cheese', "Does it say Mungo eats cheese?" );
test_test( "Finds the lacks" );


test_out(  "not ok 1 - Shouldn't say it's a test page" );
test_fail(+4);
test_diag(q(    searched: "<html>\x{0a}  <head>\x{0a}    <title>Test Page</title>\x{0a}  </h"...) );
test_diag(q(   and found: "Test Page") );
test_diag(q( at position: 27) );
$mech->content_lacks( 'Test Page', "Shouldn't say it's a test page" );
test_test( "Handles not finding it" );

cleanup();

{
  package TWMServer;
  use base 'HTTP::Server::Simple::CGI';

  sub handle_request {
    my $self=shift;
    my $cgi=shift;

    my $file=(split('/',$cgi->path_info))[-1]||'index.html';
    $file=~s/\s+//g;

    if(-r "t/html/$file") {
      if(my $response=do { local (@ARGV, $/) = "t/html/$file"; <> }) {
        print "HTTP/1.0 200 OK\r\n";
        print "Content-Type: text/html\r\nContent-Length: ",
          length($response), "\r\n\r\n", $response;
        return;
      }
    }

    print "HTTP/1.0 404 Not Found\r\n\r\n";
  }
}
