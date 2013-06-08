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
print "start:\n";
my $node_list_path = shift @ARGV;
my @node_list;
open NODE,"<$node_list_path" or die "can't open nodelist:$node_list_path";
while(<NODE>) {
	s/\r\n//;
	push @node_list,$_;
}
#count sar
my $sar_db = MongoDB::Connection->new->get_database('Sar');
my $SEC_IN_DAY = 3600*24;
my %feature_index = ();
my $start_time = {year=>2013,month=>4,day=>25};
my $end_time = {year=>2013,month=>5,day=>25};
my $start_unixtime = mktime(0,0,0,$start_time->{day},$start_time->{month}-1,
					$start_time->{year}-1900);
my $end_unixtime = mktime(0,0,0,$end_time->{day},$end_time->{month}-1,
					$end_time->{year}-1900);
#foreach node
my $total_sar_record = 0;
print "start:\n";
foreach my $node(@node_list){
	print $node."\n";
	my $sar_node_db = $sar_db->get_collection($node);
	my $sar_cur_db = $sar_node_db->find({'_id'=>
		{'$gte'=>$start_unixtime,'$lt'=>($end_unixtime + $SEC_IN_DAY)}});
	#foreach record
	while(my $sar_record = $sar_cur_db->next()) {
		$total_sar_record ++;
		delete $sar_record->{_id};
		foreach my $key(keys %$sar_record){
			foreach my $sec_key (keys %{$sar_record->{$key}}){
				ref ($sar_record->{$key}{$sec_key}) eq "" or die "lalalalala";
				my $feature_value = $sar_record->{$key}{$sec_key};
				if($feature_value == 0){next;}
				my $feature_key = "[sar] ".$key." [$sec_key]";
				unless(defined $feature_index{$feature_key}) {
					$feature_index{$feature_key} = 0;
				}
				$feature_index{$feature_key} ++;
			}
		}
	}
}
my @feature_list = sort {$feature_index{$a}<=>$feature_index{$b}} keys(%feature_index);
foreach (@feature_list) {
	print "$_ $feature_index{$_}\n";
}
#count log
