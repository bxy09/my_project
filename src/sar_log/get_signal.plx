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
#read feature_list
my %feature_index = ();
my %seldom_feature_index = ();
my $feature_list_path = shift @ARGV;
open FEATURE,"<$feature_list_path";
my $signal_no = 0;
while(<FEATURE>) {
	my ($a,$b,$num) = m/^\[sar\]\s(\S+)\s\[(\S+)\]\s(\d+)/;
	if($num < 1000) {
		defined $seldom_feature_index{$a} or $seldom_feature_index{$a} = {};
		$seldom_feature_index{$a}->{$b} = {num=>0,no=>$signal_no++};
	} else {
		defined $feature_index{$a} or $feature_index{$a} = {};
		$feature_index{$a}->{$b} = {last=>[],num=>0,pos_no=>$signal_no++,neg_no=>$signal_no++};
	}
}
sub push_in_feature {
	my($feature,$value,$a,$b,$time,$signal_col) =  @_;
  my $last_size = scalar @{$feature->{last}};
	my $sum = 0;
	my $sum_square = 0;
	foreach(@{$feature->{last}}) {
		$sum += $_;
		$sum_square += $_*$_;
	}
	push @{$feature->{last}},$value;
	if($last_size > 6) {
		my $last_one = $feature->{last}[$last_size-2];
		my $mean = $sum/$last_size;
		my $var = $sum_square/$last_size - $mean*$mean;
		#print "$a $b $mean $sum_square".Dumper($feature->{last})	if($a =~ m\inode\ and $b eq 'dentunusd');
		if($var < 0) {
			if($var > - 0.001*$mean) {
				$var = 0;
			} else {
				print Dumper($feature->{last});
				die "$a $b var:$var arithmetic error!";
			}
		}
		$var = sqrt($var);
		$var > 0 or  $var = 0.01;
		if($value > $mean + 4*$var and $value - $last_one > $var) {
			#print Dumper($feature->{last});
			$feature->{num}++;
			$signal_col->insert({"logTime"=>$time,"tempID"=>$feature->{pos_no}});
		}elsif($value < $mean - 4*$var and $value - $last_one < -$var) {
			$feature->{num}++;
			$signal_col->insert({"logTime"=>$time,"tempID"=>$feature->{neg_no}});
		}
		my $drop = shift @{$feature->{last}};
		$sum -= $drop;
		$sum_square -= $drop*$drop;
		if(1) {
		}
	}
}
sub clear_features{
	my ($features) = @_;
	foreach my $a(keys %$features) {
		foreach my $b(keys %{$features->{$a}}) {
			my $num = $features->{$a}{$b}{num};
			$features->{$a}{$b}{last} = [];
		}
	}
}
sub print_feature{
 my ($feature_index) = @_;
	foreach my $a (keys %$feature_index) {
		my $second_feature = $feature_index->{$a};
		foreach my $b(keys %$second_feature) {
			printf "%30s %20s %9d",$a,$b,$second_feature->{$b}->{num};
			if(defined $second_feature->{$b}{no}){
				printf " no:%4d\n",$second_feature->{$b}{no};
			} else {
				printf " pos_no:%4d",$second_feature->{$b}{pos_no};
				printf " neg_no:%4d\n",$second_feature->{$b}{neg_no};
			}
		}
	}
}
my $sar_db = MongoDB::Connection->new->get_database('Sar');
my $sar_signal_db = MongoDB::Connection->new->get_database('Sar_signal');
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
	my $sar_signal_node_db = $sar_signal_db->get_collection($node);
	$sar_signal_node_db->ensure_index({"logTime"=>1,"tempID"=>1});
	my $sar_cur_db = $sar_node_db->find({'_id'=>
		{'$gte'=>$start_unixtime,'$lt'=>($end_unixtime + $SEC_IN_DAY)}});
	#foreach record
	clear_features(\%feature_index);
	while(my $sar_record = $sar_cur_db->next()) {
		my $time = $sar_record->{'_id'};
		#foreach seldom feature
		foreach my $a (keys %seldom_feature_index) {
			my $second_feature = $seldom_feature_index{$a};
			if(defined $sar_record->{$a}) {
				foreach my $b(keys %$second_feature) {
					if(defined $sar_record->{$a}{$b} and $sar_record->{$a}{$b} != 0) {
						$sar_signal_node_db->insert({"logTime"=>$time,"tempID"=>$second_feature->{$b}{no}});
						$second_feature->{$b}{num}++;
					}
				}
			}
		}
		#foreach normal feature
		foreach my $a (keys %feature_index) {
			my $second_feature = $feature_index{$a};
			if(defined $sar_record->{$a}) {
				foreach my $b(keys %$second_feature) {
					if(defined $sar_record->{$a}{$b}) {
						push_in_feature($second_feature->{$b},$sar_record->{$a}{$b},$a,$b,$time,$sar_signal_node_db);
					} else {
						push_in_feature($second_feature->{$b},0,$a,$b,$time,$sar_signal_node_db);
					}
				}
			} else {
				foreach my $b(keys %$second_feature) {
					push_in_feature($second_feature->{$b},0,$a,$b,$time,$sar_signal_node_db);
				}
			}
		}
		if(defined $sar_record->{'[power]'}{'off'}) {
			$sar_record->{'[power]'}{'off'} == 1 or die;
			clear_features(\%feature_index);
		}
	}
}
print_feature(\%feature_index);
print "Seldom::::::\n";
print_feature(\%seldom_feature_index);
