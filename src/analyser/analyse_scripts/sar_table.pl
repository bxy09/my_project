#!/usr/bin/perl -w
use warnings;
use strict;
use HTML::TreeBuilder;
use HTML::Element;
use File::Basename;
use MongoDB;
use MongoDB::OID;
use POSIX;
use Data::Dumper;
use JSON;
my $script_dir = dirname(__FILE__);
#get data from mongodb,analyse
my $node_list_path = shift @ARGV;
open NODE,"<$node_list_path" or die "can't open nodelist:$node_list_path";
my @node_list = ();
while(<NODE>) {
	s/\r\n//;
	push @node_list,{name=>$_};
	#print $_."\n";
}
close NODE;
my $start_time = {year=>2013,month=>4,day=>25};
my $end_time = {year=>2013,month=>5,day=>25};
my $start_unixtime = mktime(0,0,0,$start_time->{day},$start_time->{month}-1,
					$start_time->{year}-1900);
my $end_unixtime = mktime(0,0,0,$end_time->{day},$end_time->{month}-1,
					$end_time->{year}-1900);
my $SEC_IN_DAY = 3600*24;
my $total_day_num = ($end_unixtime - $start_unixtime)/$SEC_IN_DAY + 1;

my $conn = MongoDB::Connection->new;
my $sar_db = $conn->get_database('Sar');
foreach my $node(@node_list) {
	$node->{data} = [];
	foreach(1..$total_day_num) {
		push @{$node->{data}},[0];
	}
	my $node_col = $sar_db->get_collection($node->{name});
	my $data = $node_col->find({_id=>{'$gte'=>$start_unixtime,'$lt'=>($end_unixtime+$SEC_IN_DAY)}});
	while(my $record = $data->next()) {
		my $record_unixtime = $record->{_id};
		my $record_day_offset = ($record_unixtime - $start_unixtime)/$SEC_IN_DAY;
		$record_day_offset = int($record_day_offset);
		$record_day_offset >= 0 and $record_day_offset < $total_day_num or 
			die "record day is not between the start and the end: ".
				localtime($record_unixtime);
		$node->{data}[$record_day_offset][0] ++;
	}
	#print $node->{name}."\n";
}
my $all =[[]];
foreach my $column(@node_list) {
	foreach my $record(@{$column->{data}}) {
		foreach(0){
			if($record->[$_]!=0) {
				push @{$all->[$_]}, $record->[$_];
			}
		}
	}
}
my $statics = [[]];
foreach my $data_index(0){
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
print "var data =";
print encode_json({data=>\@node_list,data_name=>"sar",statics=>$statics});
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
