#!perl

use warnings;
use strict;
use Test::More;
use Test::Exception;
use Test::Deep;
use IO::String;
use Redis;
use Redis::Dump;

use lib 't/tlib';
use Test::SpawnRedisServer;

my ( $c, $srv ) = redis();
END { $c->() if $c }

ok( my $r = Redis->new( server => $srv ), 'connected to our test redis-server' );
ok( my $dump = Redis::Dump->new( server => $srv ), 'run redis-dump' );

$r->hset( 'mhash', 'f1', 1 );
$r->hset( 'mhash', 'f2', 2 );

is_deeply( { $dump->run }, { mhash => { 'f1' => '1', 'f2' => '2' } } );

done_testing();
