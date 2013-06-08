#!/usr/bin/perl -ws
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
$parser = new Test::Parser::Sar;
$parser->parse('temp.sa');
my $data = $parser->data()->{sar};
foreach $key(keys(%$data)) {
	print "key:".$key."\n";
	print Dumper($data->{$key});
}