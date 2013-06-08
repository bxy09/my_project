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
my $JobA_col = $JobA_db->get_collection('JobAssign');
my $SEC_IN_DAY = 3600*24;
my $start_time = {year=>2013,month=>1,day=>1};
my $end_time = {year=>2013,month=>5,day=>28};
my $start_unixtime = mktime(0,0,0,$start_time->{day},$start_time->{month}-1,
					$start_time->{year}-1900);
my $end_unixtime = mktime(0,0,0,$end_time->{day},$end_time->{month}-1,
					$end_time->{year}-1900);
my $total_day_num = ($end_unixtime - $start_unixtime)/$SEC_IN_DAY + 1;
my $data       = $JobA_col->find({eventTime=>{'$gte'=>$start_unixtime},submitTime=>{'$lte'=>($end_unixtime+$SEC_IN_DAY)}});
sub duration_days{
	scalar @_ == 2 or die "parameter error";
	my ($job_start_unixtime,$job_end_unixtime) = @_;
	my $start_day = int(($job_start_unixtime -$start_unixtime)/$SEC_IN_DAY);
	my $end_day = int(($job_end_unixtime -$start_unixtime)/$SEC_IN_DAY);
	return [$start_day..$end_day];
}
sub start_day{
	scalar @_ == 2 or die "parameter error";
	my ($job_start_unixtime,$job_end_unixtime) = @_;
	my $start_day = int(($job_start_unixtime -$start_unixtime)/$SEC_IN_DAY);
	return [$start_day];
}
sub end_day{
	scalar @_ == 2 or die "parameter error";
	my ($job_start_unixtime,$job_end_unixtime) = @_;
	my $end_day = int(($job_end_unixtime -$start_unixtime)/$SEC_IN_DAY);
	return [$end_day];
}
sub node_data_init{
	open NODE,"<$node_list_path" or die "can't open nodelist:$node_list_path";
	my @node_list;
	my %name_index;
	while(<NODE>) {
		s/\r\n//;
		push @node_list,{name=>$_,data=>[]};
		$name_index{$_} = $#node_list;
		foreach(1..$total_day_num) {
			push @{$node_list[$#node_list]->{data}},[0,0,0];
		}
	}
	return (\@node_list,\%name_index,"nodes");
}
sub person_data_init{
	return ([],{},"user_name");
}
my $works = [
{data_name=>"node job duration",init=>\&node_data_init,days=>\&duration_days},
{data_name=>"node job end",init=>\&node_data_init,days=>\&end_day},
{data_name=>"person job end",init=>\&person_data_init,days=>\&end_day},
];
foreach my $work(@$works) {
	my($data,$index,$feature) = &{$work->{init}}();
	$work->{data} = $data;
	$work->{index} = $index;
	$work->{feature} = $feature;

}
my %done_mean = (0=>"unknown",32=>"known",64=>"done");
my %reason_index = (done=>0,known=>1,unknown=>2);
while (my $object = $data->next()) {
	my $start_time = $object->{startTime};
	my $submit_time = $object->{submitTime};
	$start_time = $object->{submitTime}if ($object->{submitTime} > $start_time);
	my $is_done = ${$object}{"jStatus"};
	if($is_done eq 32 and ${$object}{"exitInfo"} eq 0){
		$is_done = 0;
	}
	my $nodes = {};
	
	foreach(@{$object->{execHosts}}) {
		$nodes->{$_} = 1;
		if($_ eq 'c01b07') {
			die;
		}
	}
	my @nodes_array = keys($nodes);
	my $info = {start_time => $start_time,
		end_time => $object->{eventTime},
		done_status=>$done_mean{$is_done},
		user_name=>[$object->{userName}],
		nodes=>\@nodes_array
	};
	foreach my $work(@$works) {
		my $days = &{$work->{days}}($info->{start_time},$info->{end_time});
		my $work_data = $work->{data};
		my $work_index = $work->{index};
		my $work_feature = $work->{feature};
		foreach my $key(@{$info->{$work_feature}}) {
			my $current_index = $work_index->{$key};
			unless(defined $current_index) {
				$current_index = scalar(@{$work_data});
				$work_index->{$key} = $current_index;
				push @{$work_data},{name=>$key,data=>[]};
				foreach(1..$total_day_num) {
					push @{$work_data->[$current_index]{data}},[0,0,0];
				}
			}
			foreach my $day(@$days) {
				$day >= 0 and $day < $total_day_num or next;
				$work_data->[$current_index]{data}[$day][$reason_index{$info->{done_status}}] ++;
			}
		}
	}
}
my @out = ();
foreach my $work(@$works) {
	my $all = [[],[],[]];
	
	foreach my $column(@{$work->{data}}) {
		foreach my $record(@{$column->{data}}) {
			foreach(0..2){
				if($record->[$_]!=0) {
					push @{$all->[$_]}, $record->[$_];
				}
			}
		}
	}
	my $statics = [[],[],[]];
	foreach my $data_index(0..2){
		my $channel_data= $all->[$data_index];
		@$channel_data = sort {$a<=>$b} @$channel_data;
		my $already_get_num = 0;
		my $statics_channel = $statics->[$data_index];
		foreach my $devision_index(0..8) {#the last devision have the remain
			my $average_num = int((scalar(@$channel_data)-$already_get_num)/(10-$devision_index));
			$average_num > 0 or $average_num = 1;
			my $get_total = $average_num+$already_get_num;
			$get_total < scalar @$channel_data or last;
			my $devision_number = $channel_data->[$get_total-1];
			while($get_total < scalar @$channel_data and 
					$channel_data->[$get_total]==$devision_number) {
				$get_total ++;
			}
			push @$statics_channel,
				{num=>$get_total - $already_get_num,cover=>$channel_data->[$get_total - 1]};
			$already_get_num = $get_total;
		}
		if($already_get_num != scalar @$channel_data) {
			push @$statics_channel,
				{num=>scalar(@$channel_data) - $already_get_num,cover=>$channel_data->[scalar(@$channel_data)-1]};
			$already_get_num = scalar(@$channel_data);
		}
		@$statics_channel = reverse(@$statics_channel);
	}
	push @out,{data=>$work->{data},data_name=>$work->{data_name},statics=>$statics};
}
print "var all_data =";
print encode_json(\@out);
print ";\n";
#print date;
my @date = ();
foreach (1..$total_day_num) {
	my $time = ($_-1)*$SEC_IN_DAY + $start_unixtime;
	push @date,strftime("%m/%d",localtime($time));
}
print "var yname =";
print encode_json(\@date);
print ";\n";
