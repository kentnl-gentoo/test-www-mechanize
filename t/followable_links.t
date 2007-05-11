#!perl -T

use strict;
use warnings;
use Test::More tests => 4;
use URI::file;

use constant PORT => 13432;

my $base = 'http://localhost:'.PORT;

$ENV{http_proxy} = ''; # All our tests are running on localhost

BEGIN {
    use_ok( 'Test::WWW::Mechanize' );
}

my $server = TWMServer->new(PORT);
my $pid = $server->background;
ok($pid,'HTTP Server started') or die "Can't start the server";

sub cleanup { kill(9,$pid) if !$^S };
$SIG{__DIE__}=\&cleanup;

my $mech = Test::WWW::Mechanize->new();
isa_ok($mech,'Test::WWW::Mechanize');

$mech->get("$base/manylinks.html");

# Good links.
my @links = $mech->followable_links();
@links = map { $_->url_abs } @links;
my @expected = (
    "$base/goodlinks.html",
    'http://bongo.com/wang.html',
    'https://secure.bongo.com/',
    "$base/badlinks.html",
    "$base/goodlinks.html",
);
is_deeply( \@links, \@expected, "Got the right links" );

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
