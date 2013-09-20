#!/usr/bin/perl -w
use MongoDB;
use MongoDB::OID;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
my $conn = MongoDB::Connection->new;
my $Sar_db = $conn->get_database('Sar');
my $JobA_col = $JobA_db->JobAssign;
my $data       = $JobA_col->find(); 
my %statistic;
my @select_for_graph;
my $most_logs=0;
while (my $object = $data->next()) {
	my $id = "".${$object}{"_id"};
	my $starttime = ${$object}{"startTime"};
	 $starttime = ${$object}{"submitTime"}if (${$object}{"submitTime"} > $starttime);
	my $runtime = ${$object}{"eventTime"} - $starttime;
	my $isdone = ${$object}{"jStatus"};
	if($isdone eq 32 and ${$object}{"exitInfo"} eq 0){
		$isdone = 0;
	}
	my $flag = 0;
	foreach $node (@{${$object}{"execHosts"}}) {
		my $sar_log_count = $conn->Sar->$node->find({'_id'=>{'$gte'=>$starttime,'$lte'=>${$object}{"eventTime"}}})->count;
		if($sar_log_count != 0) {
#if ($runtime>3600 and $sar_log_count > $most_logs and $runtime<3600*5) {
#				$most_logs = $sar_log_count;
#				print "id:".${$object}{"_id"}."\tnode:".$node."\tcount:".$sar_log_count."\truntime:".$runtime."\n";
#			}
			if($runtime>3600 and $sar_log_count*610>$runtime) {
				push @select_for_graph,{id=>$id,node=>$node,count=>$sar_log_count,runtime=>$runtime};
				print "id:".$id."\tnode:".$node."\tcount:".$sar_log_count."\truntime:".$runtime."\n";
			}
			$flag = 1;
		}
	}
	$flag or next;
	if(${$object}{"eventTime"}>mktime(0,0,0,5,8,2012-1900) || ${$object}{"eventTime"}<mktime(0,0,0,4,5,2012-1900)){#月份从0开始
		print localtime(${$object}{"eventTime"})."\n";
		$JobA_col->remove({"_id"=>$id});
		next;
#		print localtime(${$object}{"startTime"})."\n";
#		last;
	}
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
}
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