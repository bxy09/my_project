#!/usr/bin/perl -w
use MongoDB;
use MongoDB::OID;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
my $conn = MongoDB::Connection->new;
my $JobA_db = $conn->get_database('JobAssign');
my $JobA_col = $JobA_db->get_collection('JobAssign');
my $data       = $JobA_col->find(); 
my $jobNum = 0;
my %statistic;
my @select_for_graph;
my $most_logs=0;
my %users;
$TIME_MARGIN = 10;
while (my $object = $data->next()) {
	my $id = "".${$object}{"_id"};
	my $starttime = ${$object}{"startTime"};
	my $submitTime = $object->{submitTime};
	 $starttime = ${$object}{"submitTime"}if (${$object}{"submitTime"} > $starttime);
	my $endTime = $object->{eventTime};
	my $runtime = $endTime - $starttime;
	my $isdone = ${$object}{"jStatus"};
	my $userId = $object->{userID};
	my $userName = $object->{userName};
	if($isdone eq 32 and ${$object}{"exitInfo"} eq 0){
		$isdone = 0;
	}
	#isdone = [0 unknown reason,32 exit,64 done]
	if(${$object}{"submitTime"}>mktime(0,0,0,5,8,2012-1900) || ${$object}{"eventTime"}<mktime(0,0,0,4,5,2012-1900)){#月份从0开始
	#if(${$object}{"eventTime"}>mktime(0,0,0,5,8,2012-1900) || ${$object}{"eventTime"}<mktime(0,0,0,4,5,2012-1900)){#月份从0开始
	#	print localtime(${$object}{"eventTime"})."\n";
		#$JobA_col->remove({"_id"=>$id});
		next;
#		print localtime(${$object}{"startTime"})."\n";
#		last;
	}
	$jobNum += 1;
	unless(defined $users{$userId}) {
		$users{$userId}->{name} = $userName;
		$users{$userId}->{workflow} = [];
	}
	my $find_flow = 0;
	foreach my $flow(@{$users{$userId}->{workflow}}) {
		if($flow->{submitTime} - $submitTime < $TIME_MARGIN and 
			$flow->{endTime} - $submitTime > -$TIME_MARGIN ) {
			$flow->{count} ++;
			push @{$flow->{work_in_flow}}, $id;
			push @{$flow->{exit_info}}, $isdone;
			$flow->{submitTime} =$submitTime if($submitTime < $flow->{submitTime});
			$flow->{endTime} = $endTime if($endTime < $flow->{endTime});
			$find_flow = 1;
			last;
		}
	}
	unless($find_flow) {
		my $flow ->{submitTime} = $submitTime;
		$flow ->{endTime} = $endTime;
		$flow ->{count} = 1;
		$flow ->{work_in_flow} = [$id];
		$flow ->{exit_info} = [$isdone];
		$flow ->{runtime} = $runtime;
		push @{$users{$userId}->{workflow}}, $flow;
	}
=pod
	if(defined($statistic{$isdone}->{floor($runtime/600)})) {
		$statistic{$isdone}->{floor($runtime/600)} += 1;
	}else {
		$statistic{$isdone}->{floor($runtime/600)} = 1;
	}
	if($runtime > 3600*24*90) {
	foreach my $key (keys %{$object}) {
        print "$key => ${$object}{$key}";
		if($key eq "eventTime" or $key eq "startTime"){
			print "\t".localtime(${$object}{$key})."\n";
		}
    }
	die "runtime:".$runtime."\twtf!!\n";
	}
=cut
}
#merge the workflow
my $nochange = 0;
until($nochange) {
	$nochange = 1;
	while (my($key,$value) = each %users) {
		foreach my $i(0..$#{@{$value->{workflow}}}) {
			foreach my $j(($i + 1)..$#{@{$value->{workflow}}}) {
				my $workflow_i = $value->{workflow}->[$i];
				my $workflow_j = $value->{workflow}->[$j];
				if(( $workflow_i->{submitTime} - $workflow_j->{submitTime} < $TIME_MARGIN && 
					 $workflow_i->{endTime} - $workflow_j->{submitTime} > -$TIME_MARGIN)  or (
					 $workflow_j->{submitTime} - $workflow_i->{submitTime} < $TIME_MARGIN && 
					 $workflow_j->{endTime} - $workflow_i->{submitTime} > -$TIME_MARGIN)) {
					$nochange = 0;
					#merge workflow
					if($workflow_j->{submitTime} < $workflow_i->{submitTime}) {
						$workflow_i->{submitTime} = $workflow_j->{submitTime};
					}
					if($workflow_j->{endTime} > $workflow_i->{endTime}) {
						$workflow_i->{endTime} = $workflow_j->{endTime};
					}
					$workflow_i ->{count} += $workflow_i ->{count};
					push @{$workflow_i ->{work_in_flow}},@{$workflow_j ->{work_in_flow}};
					push @{$workflow_i ->{exit_info}},@{$workflow_j ->{exit_info}};
					delete $value->{workflow}->[$j];
					next;
				}
			}
		}
	}
}
my $workflow_num = 0;
my $workflow_1_job = {sum=>0,done=>0,exit=>0,unknown=>0,unknown_gt_1min=>0};
my $workflow_le_5_job = {sum=>0,done=>0,exit=>0,unknown=>0};
my $workflow_gt_5_job = {sum=>0,done=>0,exit=>0,unknown=>0};
my $temp_flag =3;
open OUTPUT,">user.txt" or die 'can\'t open user.txt';
my %exit_code = (0=>'unknown',32=>'exit',64=>'done');
while (my($key,$value) = each %users) {
#	print OUTPUT $key.":".$value->{name}.":".scalar @{$value->{workflow}}."\n";
	$workflow_num += scalar @{$value->{workflow}};
	foreach my $workflow(@{$value->{workflow}}) {
		if($workflow->{count} == 1) {
			$workflow_1_job->{sum} ++;
			defined $exit_code{$workflow->{exit_info}->[0]} or print $workflow->{exit_info}->[0]."\n";
			$workflow_1_job->{$exit_code{$workflow->{exit_info}->[0]}} ++;
			if($exit_code{$workflow->{exit_info}->[0]} eq 'unknown' and $workflow->{runtime} > 60) {
				$workflow_1_job->{unknown_gt_1min} ++;
			}
		}
		if($workflow->{count} > 1 and $workflow->{count} <= 5) {
			$workflow_le_5_job->{sum} ++;
			my $is_done = 'done';
			foreach my $exit_info(@{$workflow->{exit_info}}) {
				unless($exit_code{$exit_info} eq 'done') {
					$is_done = $exit_code{$exit_info};
					last if($is_done eq 'unknown');
				}
			}
			$workflow_le_5_job->{$is_done}++;
		}
		if($workflow->{count} > 5) {
			
			$workflow_gt_5_job->{sum} ++;
			my $is_done = 'done';
			foreach my $exit_info(@{$workflow->{exit_info}}) {
				unless($exit_code{$exit_info} eq 'done') {
					$is_done = $exit_code{$exit_info};
					last if($is_done eq 'unknown');
				}
			}
			$workflow_gt_5_job->{$is_done}++;
		}
	}
}
print OUTPUT "jobNum:$jobNum\n";
print OUTPUT "workflow num:$workflow_num\n";
print OUTPUT "workflow_1_job:".Dumper($workflow_1_job)."\n";
print OUTPUT "workflow_le_5_job:".Dumper($workflow_le_5_job)."\n";
print OUTPUT "workflow_gt_5_job:".Dumper($workflow_gt_5_job)."\n";
=put
open OUTPUT,">out.txt";
foreach my $key (keys %statistic) {
	print OUTPUT $key.":\n";
	my $sum = 0;
	foreach my $time (reverse sort by_number keys %{$statistic{$key}}) {
		my $num = $statistic{$key}->{$time};
		$sum += $num;
		print OUTPUT "\t".$time."\t".$num."\t".$sum."\n";
	}
}
open SELECT_OUT,">select_out.txt";
print SELECT_OUT Dumper(@select_for_graph);
sub by_number {$a<=>$b};
=cut
