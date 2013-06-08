#!/usr/bin/perl -w
use warnings;
use strict;
use MongoDB;
use MongoDB::OID;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
use JSON;
#read nodelist
my $node_list_path = shift @ARGV;
my @node_list;
open NODE,"<$node_list_path" or die "can't open nodelist:$node_list_path";
while(<NODE>) {
	s/\r\n//;
	push @node_list,$_;
}
close NODE;
my $sar_db = MongoDB::Connection->new->get_database('Sar');
my $SEC_IN_DAY = 3600*24;
my $start_time = {year=>2013,month=>4,day=>25};
my $end_time = {year=>2013,month=>5,day=>25};
my $start_unixtime = mktime(0,0,0,$start_time->{day},$start_time->{month}-1,
					$start_time->{year}-1900);
my $end_unixtime = mktime(0,0,0,$end_time->{day},$end_time->{month}-1,
					$end_time->{year}-1900);
#foreach node
my $total_sar_record = 0;
foreach my $node(@node_list){
	print $node."\n";
	my $sar_node_db = $sar_db->get_collection($node);
	my $sar_cur_db = $sar_node_db->find({'_id'=>
		{'$gte'=>$start_unixtime,'$lt'=>($end_unixtime + $SEC_IN_DAY)}})->sort({'_id'=>1});
	#foreach record
	my $last_timestamp = -1;
	my $last_have_on = 0;
	my $power_on = 0;
	while(my $sar_record = $sar_cur_db->next()) {
		#$power_on ++ if(defined $sar_record->{'[power]'}{'on'});
		#$power_on -- if(defined $sar_record->{'[power]'}{'off'});
		my $current_timestamp = $sar_record->{_id};
		if($last_timestamp > 0 and $current_timestamp - $last_timestamp > 60*14) {
			if($last_have_on) {
				$sar_node_db->update({_id=>$last_timestamp},{'[power]'=>{'off'=>1,'on'=>1}});
			} else {
				$sar_node_db->update({_id=>$last_timestamp},{'[power]'=>{'off'=>1}});
			}
			$sar_node_db->update({_id=>$current_timestamp},{'[power]'=>{'on'=>1}});
			print "power off\n";
			print $last_timestamp.":".$current_timestamp."\n";
			$last_have_on = 1;
			$last_timestamp = $current_timestamp;
		} else {
			$last_have_on = 0;
			$last_timestamp = $current_timestamp;
		}
	}
	#die if($power_on != 0);
}
