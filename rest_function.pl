use strict;
use MongoDB;
use MongoDB::OID;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
use threads;
use threads::shared;
use Thread::Queue;
#read nodelist
my $node_list_path = shift @ARGV;
my @nodes;
open NODE,"<$node_list_path" or die "can't open nodelist:$node_list_path";
while(<NODE>) {
	s/\r\n//;
	push @nodes,$_;
}
close NODE;

my ($start_time,$day_count,$sar_pos,$sar_neg,$log_db,$log_tempID) = @ARGV;

($start_time,$day_count,$sar_pos,$sar_neg,$log_db,$log_tempID) = (1366819200,1,37,38,'lim',0);
	my %answer:shared;
	print "ininin\n";
	my $index = 0;
	foreach my $node(@nodes) {
		print LOG $node."\n";
		$index ++;
		my %content:shared;
		%content = (sar=>0,log=>0,job=>0);
		$answer{$node} = \%content;
	}
my @read_pool;
my $read_queue = Thread::Queue->new();
$read_queue->enqueue(@nodes);
my $threads_num = 20;
foreach my $thread_id(0..($threads_num-1)) {
	push @read_pool,threads->create(\&get_node_abstraction,\%answer,$read_queue,
					$start_time,$day_count,$sar_pos,$sar_neg,$log_db,$log_tempID);
}
$read_queue->end;
foreach (@read_pool){
	$_->join;
}
	print Dumper(\%answer);

sub get_node_abstraction {
	my ($answer,$read_queue,$start_time,$day_count,$sar_pos,$sar_neg,$log_db,$log_tempID)= @_;
	my $sar_signal_db = MongoDB::Connection->new->get_database('Sar_signal');
	my $log_signal_db = MongoDB::Connection->new->get_database($log_db);
	my $job_db = MongoDB::Connection->new->get_database('JobAssign');
	my $end_time = $start_time +($day_count)*3600*24;
	my $node;
	while(defined ($node = $read_queue->dequeue())) {
		if($sar_neg >= 0) {
			$answer->{$node}{sar} = 
			$sar_signal_db->get_collection($node)->
				count({'tempID'=>{'$in'=>[$sar_pos,$sar_neg]},
				'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
		} else {
			$answer->{$node}{sar} = 
			$sar_signal_db->get_collection($node)->
				count({'tempID'=>$sar_pos,
				'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
		}
		#get_log
		$answer->{$node}{log} = 
			$log_signal_db->get_collection($node)->
				count({'tempID'=>$log_tempID,
				'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
		#get_job
		$answer->{$node}{job} = 
			$job_db->get_collection('JobAssign')->
				count({'eventTime'=>{'$gte'=>$start_time},
	  	 'submitTime'=>{'$lte'=>$end_time},
	  	 'startTime'=>{'$lte'=>$end_time}});
	  	 #'execHosts'=>$node});
	}
}
