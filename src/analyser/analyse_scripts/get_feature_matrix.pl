#!/usr/bin/perl -w
use warnings;
use strict;
use MongoDB;
use MongoDB::OID;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
use JSON;
my $node_list_path = shift @ARGV;
my $conn = MongoDB::Connection->new;
my $JobA_db = $conn->get_database('JobAssign');
my $job_col = $JobA_db->get_collection('JobAssign');
my $sar_db = MongoDB::Connection->new->get_database('Sar');
my $SEC_IN_DAY = 3600*24;
my $time_node_zones =[{time=>["5/1","5/10"],node=>['c01b09','c01b20']}
										 ];
my @log_types = qw/cron messages secure lim mbatchd mbschd sbatchd pim res/;
my %log_dbs = ();

open NODE,"<$node_list_path" or die "can't open nodelist:$node_list_path";
my @node_list;
my %name_index;
while(<NODE>) {
	s/\r\n//;
	push @node_list,$_;
	$name_index{$_} = $#node_list;
}
foreach my $log_type(@log_types) {
	$log_dbs{$log_type} =  MongoDB::Connection->new->get_database($log_type);
	foreach my $node(@node_list) {
		$log_dbs{$log_type}->get_collection($node)->ensure_index({logTime=>1});
	}
}
my %feature_list = ();
my %feature_index = ();
my $feature_num = 0;
foreach my $time_zone(@$time_node_zones) {
	my @nodes = @node_list[$name_index{$time_zone->{node}[0]}..
	$name_index{$time_zone->{node}[1]}];
	my ($month,$day) = $time_zone->{time}[0]=~m{(\d+)/(\d+)};
	my $start_time = {year=>2013,month=>$month,day=>$day};
	($month,$day) = $time_zone->{time}[1]=~m{(\d+)/(\d+)};
	my $end_time = {year=>2013,month=>$month,day=>$day};
	my $start_unixtime = mktime(0,0,0,$start_time->{day},$start_time->{month}-1,
						$start_time->{year}-1900);
	my $end_unixtime = mktime(0,0,0,$end_time->{day},$end_time->{month}-1,
						$end_time->{year}-1900);
	my $total_day_num = ($end_unixtime - $start_unixtime)/$SEC_IN_DAY + 1;
	#my $data = $job_col->find({eventTime=>{'$gte'=>$start_unixtime},submitTime=>{'$lte'=>($end_unixtime+$SEC_IN_DAY)}});
	foreach my $node(@nodes){
		print $node."\n";
		my $sar_node_db = $sar_db->get_collection($node);
		my $sar_cur_db = $sar_node_db->find({'_id'=>
			{'$gte'=>$start_unixtime,'$lt'=>($end_unixtime + $SEC_IN_DAY)}});
		#get sar feature and record timepoint
		while(my $sar_record = $sar_cur_db->next()){
			my $record_time = $sar_record->{_id};
			my $features = [];
			delete $sar_record->{_id};
			#get other feature from sar record;
			foreach my $key(keys %$sar_record){
				foreach my $sec_key (keys %{$sar_record->{$key}}){
					ref ($sar_record->{$key}{$sec_key}) eq "" or die "lalalalala";
					my $feature_value = $sar_record->{$key}{$sec_key};
					if($feature_value == 0){next;}
					my $feature_key = "[sar]".$key."[$sec_key]";
					my $cur_feature_index;
					if(defined  $feature_index{$feature_key}) {
						$cur_feature_index= $feature_index{$feature_key};
					}else {
						$cur_feature_index= $feature_num;
						$feature_index{$feature_key} = $feature_num;
						$feature_num++;
					}
					$features->[$cur_feature_index] = $feature_value;
				}
			}
			#get feature from logs;
			foreach my $log_type(@log_types) {
		#$log_dbs{$log_type}->get_collection($node)->ensure_index({logTime=>1});
				my $log_cur = $log_dbs{$log_type}->get_collection($node)->find({logTime=>{'$gte'=>$record_time -300,'$lt'=>$record_time+300}});
				while(my $log_record = $log_cur->next()){
					my $feature_key = "[$log_type][".$log_record->{tempID}."]";
					my $cur_feature_index;
					if(defined  $feature_index{$feature_key}) {
						$cur_feature_index= $feature_index{$feature_key};
					}else {
						$cur_feature_index= $feature_num;
						$feature_index{$feature_key} = $feature_num;
						$feature_num++;
					}
					if(defined $features->[$cur_feature_index]) {
						$features->[$cur_feature_index] ++;
					} else {
						$features->[$cur_feature_index] = 1;
					}
				}
			}
			#push feature
			my $out_node = $node;
			$out_node =~ s/[cb]//g;
			my $record_key = $out_node." ".$record_time;
			defined $feature_list{$record_key} and die "[$record_key] replicate record";
			$feature_list{$record_key} = $features;
		}
	}
}
#output
open OUT,">out_2.txt";
print OUT $feature_num." ".scalar(keys %feature_list)."\n";
while (my ($record_key,$record) = each %feature_list){
	print OUT $record_key." ";
	foreach my $feature(@$record) {
		unless(defined $feature){
			print OUT "0 ";
		} else {
			print OUT $feature." ";
		}
	}
	foreach(1..($feature_num - scalar @$record)){
		$feature_num >= scalar (@$record) or die "laweualeifj";
		print OUT "0 ";
	}
	print OUT "\n";
}
close OUT;
#output feature_name
open FEA_OUT,">feature_out_2.txt";
my @feature_name_list;
foreach my $feature_name (keys(%feature_index)) {
	$feature_name_list[$feature_index{$feature_name}] = $feature_name;
}
print FEA_OUT $_."\n" foreach @feature_name_list;

