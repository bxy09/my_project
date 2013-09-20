#!/usr/bin/perl -w
use warnings;
use strict;
use MongoDB;
use MongoDB::OID;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
use JSON;
my $conn = MongoDB::Connection->new;
my $JobA_db = $conn->get_database('JobAssign');
my $JobA_col = $JobA_db->get_collection('JobAssign');
my $data       = $JobA_col->find();
my %done_mean = (0=>"unknown",32=>"known",64=>"done");
my %reason_index = (done=>0,known=>1,unknown=>2);
my %month;
while (my $object = $data->next()) {
	my $start_time = $object->{startTime};
	my $submit_time = $object->{submitTime};
	$start_time = $object->{submitTime}if ($object->{submitTime} > $start_time);
	my $is_done = ${$object}{"jStatus"};
	if($is_done eq 32 and ${$object}{"exitInfo"} eq 0){
		$is_done = 0;
	}
	my @job_month = localtime($start_time);
	$job_month[4] += 1;#month
	$job_month[5] += 1900;#year
	my $job_month = sprintf "%4d/%02d",$job_month[5],$job_month[4];
	unless(defined $month{$job_month}) {
	 $month{$job_month}={all=>{unknown=>0,known=>0,done=>0},clear=>{unknown=>0,known=>0,done=>0}};
	}
	$month{$job_month}->{all}{$done_mean{$is_done}} ++;
		die "$job_month" if($object->{numExHosts} == 0) ;
	if(scalar @{$object->{execHosts}} > 0) {
		die if($object->{numExHosts} == 0) ;
		$month{$job_month}->{clear}{$done_mean{$is_done}} ++;
	}
}
foreach my $cur_month (sort keys %month) {
	printf "%s all:[",$cur_month;
	foreach my $key (sort keys %{$month{$cur_month}->{all}}) {
		printf "%s:%10d,",$key,$month{$cur_month}->{all}{$key};
	}
	print "] clear:[";
	foreach my $key (sort keys %{$month{$cur_month}->{clear}}) {
		printf "%s:%10d,",$key,$month{$cur_month}->{clear}{$key};
	}
	print "]\n";
}
