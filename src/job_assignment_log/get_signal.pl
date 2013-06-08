#!/usr/bin/perl -w
use warnings;
use strict;
use MongoDB;
use MongoDB::OID;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
use JSON;
my %node_handles = ();
my $job_assign_cl = MongoDB::Connection->new->get_database('JobAssign')->get_collection('JobAssign');
my $job_signal_db = MongoDB::Connection->new->get_database('Job_signal');
my $SEC_IN_DAY = 3600*24;
my $start_time = {year=>2013,month=>4,day=>25};
my $end_time = {year=>2013,month=>5,day=>25};
my $start_unixtime = mktime(0,0,0,$start_time->{day},$start_time->{month}-1,
					$start_time->{year}-1900);
my $end_unixtime = mktime(0,0,0,$end_time->{day},$end_time->{month}-1,
					$end_time->{year}-1900);
my $data = $job_assign_cl->find({eventTime=>{'$gte'=>$start_unixtime},submitTime=>{'$lte'=>($end_unixtime+$SEC_IN_DAY)}});
my $exit_code_num = 0;
my %new_exit_code = ();
my $nohosts_trash_job_num = 0;
my $time_trash_job_num = 0;

while (my $object = $data->next()) {
	my $execHosts = $object->{execHosts};
	if(scalar @$execHosts == 0) {$nohosts_trash_job_num ++; next;}
	my $start_time = $object->{startTime};
	my $event_time = $object->{eventTime};
	my $submit_time = $object->{submitTime};
	$start_time = $object->{submitTime}if ($object->{submitTime} > $start_time);
	if ($event_time - $start_time < 30) {$time_trash_job_num ++; next;}#the time constraint
	my $uniq_hosts = {};
	foreach (@$execHosts) {$uniq_hosts->{$_} = 1;}
	my $jStatus = ${$object}{"jStatus"};
	my $exit_info = ${$object}{"exitInfo"};
	my $old_exit_code = "j:$jStatus e:$exit_info";
	unless(defined $new_exit_code{$old_exit_code}) {
		#code 0 for job start
		$new_exit_code{$old_exit_code} = {code=>1+$exit_code_num++,num=>0};
	}
	my $ex_code = $new_exit_code{$old_exit_code}->{code};
	$new_exit_code{$old_exit_code}->{num}++;
	foreach my $node(keys %$uniq_hosts) {
		unless(defined $node_handles{$node}) {
			$node_handles{$node} = MongoDB::Connection->new->get_database('Job_signal')->get_collection($node);
			$node_handles{$node}->ensure_index({"logTime"=>1,"tempID"=>1});
		}
		$node_handles{$node}->insert({"logTime"=>$start_time,
																	"tempID"=>0});
		$node_handles{$node}->insert({"logTime"=>$event_time,
																	"tempID"=>$ex_code});
	}
}
print "no hosts trash:$nohosts_trash_job_num\n";
print "time trash:$time_trash_job_num\n";
foreach my $old_key(keys %new_exit_code) {
	printf "%10s new_id:%4d num:%10d\n",$old_key,$new_exit_code{$old_key}->{code},$new_exit_code{$old_key}->{num};
}
