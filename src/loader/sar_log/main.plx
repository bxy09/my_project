#!/usr/bin/perl -w
use warnings;
use strict;
use MongoDB;
use MongoDB::OID;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
my $CPU_IDLE_THRESHOLD = 50.0;
@ARGV == 1 or die "para error!\n\tneed para sar_log_dir_path";
my $dir_path = $ARGV[0];
my @satar_list = `ls $dir_path`;
my $conn = MongoDB::Connection->new;
my $Sar_db = $conn->get_database('Sar');
my $have_time = 0;
my $feature_count_store = {num=>0,info=>'',member=>[]};
foreach my $tar_name(@satar_list) {
	my $file_path = $dir_path.$tar_name;
	print $file_path;
	system "tar -xvf $file_path ";
#edit for temp_use
	my ($temp_date) = $file_path =~ m/(\d+)\.tar.gz/;
	system("mv tmp_$temp_date/* .");
	system("rm -r tmp_$temp_date");
	system("rm sa_*ln*");
#end edit for temp_use
	my @specific_file_name_list = `ls sa_*`;
	print "////////////////////\n";
	foreach my $specific_file_name(@specific_file_name_list) {
		chomp $specific_file_name;
		my($node,$year,$month,$day) =
			 $specific_file_name =~ /^sa_(\S+)_(\d\d\d\d)(\d\d)(\d\d)$/;
		my $Node_col = $Sar_db->get_collection($node);
		my $parser = new Test::Parser::Sar;
		print "parse $specific_file_name\n";
		$parser->parse($specific_file_name);
		my $data = $parser->data()->{sar};
		my $info_from_file = {};
		my $time_hash = {};
		#get all features
		#time:find near one
		#!recursion
		$have_time = 0;
		getInfo($info_from_file,$data,{year=>$year,
						month=>$month,day=>$day},'');
		foreach my $timestamp(sort keys %$info_from_file) {
			my $all_features = $info_from_file->{$timestamp};
			#analyse cpu features
			#delete som features CPU,INTR
			my $running_cpu_count = 0;
			defined $all_features->{'[cpu][cpu:all]'} or
					 die "don't have [cpu][cpu:all]record! in ".
						localtime $timestamp;
			my $cpu_all = $all_features->{'[cpu][cpu:all]'};
			my $io_dev_all = {tps=>0,util_ratio=>0,rd_sec_s=>0,
												svctm=>0,wr_sec_s=>0,avgqu_sz=>0,
												avgrq_sz=>0,await=>0};
			my $feature_count = [];
			my $network_ok_all = {};
			my $network_err_all = {};
			foreach my $class(keys %$all_features) {
				if($class =~ m{^\[intr\]}) {
					delete $all_features->{$class};
					next;
				}
				if($class =~ m{^\[cpu\]\[cpu:\d*\]}) {
					if($all_features->{$class}{idle} <
							 $CPU_IDLE_THRESHOLD) {
						if($running_cpu_count == 0) {
							foreach my $feature (keys %$cpu_all) {
								$cpu_all->{$feature} = 0;
							}
						}
						$running_cpu_count ++;
						foreach my $feature (keys %$cpu_all) {
							$cpu_all->{$feature}  +=
								 $all_features->{$class}{$feature};
						}
					}
					delete $all_features->{$class};
					next;
				}
				if($class =~ m{^\[io\]\[bd\]\[dev:.*\]}){
					foreach my $feature (keys %{$all_features->{$class}}){
						defined $io_dev_all->{$feature} or
							$io_dev_all->{$feature} = 0;
						$io_dev_all->{$feature} += $all_features->{$class}{$feature};
					}
					delete $all_features->{$class};
					next;
				}
				if($class =~ m{^\[network\]\[.*\]\[iface:.*\]}){
					my $cum = $network_err_all;
					$cum = $network_ok_all if($class =~m{\[ok\]});
					foreach my $feature (keys %{$all_features->{$class}}){
						defined $cum->{$feature} or
							$cum->{$feature} = 0;
						$cum->{$feature} += $all_features->{$class}{$feature};
					}
				}
				#delete zero features
				next if($class eq '[cpu][cpu:all]');
				foreach my $feature (keys %{$all_features->{$class}}){
					push  @$feature_count, $class."[$feature]";
					$all_features->{$class}{$feature} != 0 or
						 delete $all_features->{$class}{$feature};
				}
				scalar(keys %{$all_features->{$class}}) != 0 or
					delete $all_features->{$class};
			}
			$running_cpu_count >= 0 or
				 die "running_cpu_count can't be negative";
			if($running_cpu_count != 0) {
				foreach my $feature (keys %$cpu_all) {
					$cpu_all->{$feature} =
						$cpu_all->{$feature}/$running_cpu_count;
					$cpu_all->{$feature} =0+ (sprintf "%.2f",$cpu_all->{$feature});
				}
			}
			$cpu_all->{running_cpu_count} = $running_cpu_count;
			#print / validate features!!
			push @$feature_count ,"[cpu][cpu:all][$_]"
				 foreach keys(%$cpu_all);
			$all_features->{'[io][bd][dev:all]'}=$io_dev_all;
			push @$feature_count ,"[io][bd][dev:all][$_]"
				foreach keys(%$io_dev_all);
			$all_features->{'[network][err][iface:all]'}=$network_err_all;
			$all_features->{'[network][ok][iface:all]'}=$network_ok_all;
			push @$feature_count ,"[network][ok][iface:all][$_]"
				foreach keys(%$network_ok_all);
			push @$feature_count ,"[network][err][iface:all][$_]"
				foreach keys(%$network_err_all);
			if($feature_count_store->{num} == 0) {
				$feature_count_store->{num} =0+ scalar(@$feature_count);
				$feature_count_store->{member} =$feature_count;
				$feature_count_store->{info} = localtime($timestamp)." ".
					$node;
			}
			if(scalar(@$feature_count) != $feature_count_store->{num}) {
				open DEBUG_OUT, ">debug.info";
				print DEBUG_OUT "store:\n";
				print DEBUG_OUT $_."\n"
					foreach (@{$feature_count_store->{member}});
				print DEBUG_OUT "current:\n";
				print DEBUG_OUT $_."\n" foreach (@$feature_count);
				die "don't have same number of features \ncurrent: $node ".
					scalar(@${feature_count}).localtime($timestamp).
					 "\nstore: ".$feature_count_store->{num}." ".
					 $feature_count_store->{info};
			}
			#insert in mongodb
			$all_features->{_id} = $timestamp+0;
			$Node_col->insert($all_features);
		}
	}
	system "rm sa_*";
}

sub getInfo{
	my ($info_from_file, $data, $date, $last_level_key) = @_[0,1,2,3];
	if(ref($data) eq 'ARRAY') {
		foreach my $element (@$data) {
			my($hour,$min,$sec) = 
				$element->{time} =~ /^(\d{2}):(\d{2}):(\d{2})$/;
			my $unix_timestamp = 
				mktime(0,$min,$hour,$date->{day},$date->{month}-1,
					$date->{year}-1900);
			if($have_time) {
				defined $info_from_file->{$unix_timestamp} or
					die "different time stamp! of $last_level_key in".
						localtime($unix_timestamp);
				if(defined($info_from_file->{$unix_timestamp}{$last_level_key})){
					warn "WARN A duplicate record! of $last_level_key in".
						localtime($unix_timestamp);
					next;
				}
				delete $element->{time};
				$info_from_file->{$unix_timestamp}{$last_level_key} =
					$element;
			} else {
				if(defined($info_from_file->{$unix_timestamp})){
					warn "WARN duplicate record! of $last_level_key in ".
						localtime($unix_timestamp);
					next;
				}
				delete $element->{time};
				$info_from_file->{$unix_timestamp}{$last_level_key} =
					$element;
			}
		}
		$have_time = 1;	

	} else {
		foreach my $key (keys (%$data)) {
			getInfo($info_from_file, $data->{$key}, $date, $last_level_key.
				"[$key]");
		}
	}
}
