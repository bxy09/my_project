use Dancer;
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
my @signals = (
	{db=>'lim',num=>7},
	{db=>'pim',num=>1},
	{db=>'res',num=>15},
	{db=>'sbatchd',num=>20},
	{db=>'messages',num=>2}
);
get '/log_abstract' => sub {
	content_type 'application/json';
	my $time = param 'time';
	my $node = param 'node';
	my %answer:shared;
	my $sar_sig_num = 181;
	my $read_queue = Thread::Queue->new();
	foreach my $signal(@signals) {
		foreach my $tempID((0..($signal->{num}-1))) {
			$read_queue->enqueue("$signal->{db} $tempID");
			$answer{"$signal->{db} $tempID"} = 0;
		}
	}
	my @read_pool;
	my $threads_num = 4;
	foreach my $thread_id(0..($threads_num-1)) {
		push @read_pool,threads->create(\&get_log_abstraction,\%answer,$read_queue,
						$time,$node);
	}
	$read_queue->end;
	foreach (@read_pool){
		$_->join;
	}
	return to_json(\%answer);
};
get '/sar_abstract' => sub {
	content_type 'application/json';
	my $time = param 'time';
	my $node = param 'node';
	my @answer:shared;
	my $sar_sig_num = 181;
	foreach my $day_index(1..$sar_sig_num) {
		push @answer,0;
	}
	my @read_pool;
	my $read_queue = Thread::Queue->new();
	$read_queue->enqueue((0..($sar_sig_num-1)));
	my $threads_num = 4;
	foreach my $thread_id(0..($threads_num-1)) {
		push @read_pool,threads->create(\&get_sar_abstraction,\@answer,$read_queue,
						$time,$node);
	}
	$read_queue->end;
	foreach (@read_pool){
		$_->join;
	}
	return to_json(\@answer);
};
get '/days_abstract' => sub {
	content_type 'application/json';
	my $target;
	my $start_time = param 'start_time';
	my $day_count = param 'day_count';
	my $sar_pos = param 'sar_pos';
	my $sar_neg = param 'sar_neg';
	my $log_db = param 'log_db';
	my $log_tempID = param 'log_tempID';
	my $node = param 'node';
	my @answer:shared;
	foreach my $day_index(1..$day_count) {
		my %content:shared;
		%content = (sar=>0,log=>0,job=>0);
		push @answer,\%content;
	}
	my @read_pool;
	my $read_queue = Thread::Queue->new();
	$read_queue->enqueue((0..($day_count-1)));
	my $threads_num = 4;
	foreach my $thread_id(0..($threads_num-1)) {
		push @read_pool,threads->create(\&get_day_abstraction,\@answer,$read_queue,
						$start_time,$sar_pos,$sar_neg,$log_db,$log_tempID,$node);
	}
	$read_queue->end;
	foreach (@read_pool){
		$_->join;
	}
	return to_json(\@answer);
};

sub get_log_abstraction {
	my ($answer,$read_queue,$time,$node)= @_;
	my $start_time = $time;
		$start_time += 0;
	my $end_time = $time + 3600*24;
	my $pair = '';
	while(defined ($pair = $read_queue->dequeue())) {
		my ($log_db,$log_id) = ($pair =~ m/^(\S+)\s+(\d+)/);
		my $log_signal_col = MongoDB::Connection->new->get_database($log_db)
		->get_collection($node);
		$log_id += 0;
		$answer->{$pair} = 
		$log_signal_col->
			count({'tempID'=>$log_id,
			'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
	}
}
sub get_sar_abstraction {
	my ($answer,$read_queue,$time,$node)= @_;
	my $sar_signal_col = MongoDB::Connection->new->get_database('Sar_signal')
		->get_collection($node);
	my $start_time = $time;
		$start_time += 0;
	my $end_time = $time + 3600*24;
	my $sig_index = 0;
	while(defined ($sig_index = $read_queue->dequeue())) {
		$sig_index += 0;
		$answer->[$sig_index] = 
		$sar_signal_col->
			count({'tempID'=>$sig_index,
			'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
	}
}
sub get_day_abstraction {
	my ($answer,$read_queue,$first_day,$sar_pos,$sar_neg,$log_db,$log_tempID,$node)= @_;
	$log_tempID = $log_tempID +0;
	$sar_pos += 0;
	$sar_neg += 0;
	my $sar_signal_db = MongoDB::Connection->new->get_database('Sar_signal');
	my $log_signal_db = MongoDB::Connection->new->get_database($log_db);
	my $job_db = MongoDB::Connection->new->get_database('Job_signal');
	my $day_index;
	while(defined ($day_index = $read_queue->dequeue())) {
		my $start_time = $first_day+($day_index)*3600*24;
		my $end_time = $first_day+($day_index+1)*3600*24;
		if($sar_neg >= 0) {
			$answer->[$day_index]{sar} = 
			$sar_signal_db->get_collection($node)->
				count({'tempID'=>{'$in'=>[$sar_pos,$sar_neg]},
				'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
		} else {
			$answer->[$day_index]{sar} = 
			$sar_signal_db->get_collection($node)->
				count({'tempID'=>$sar_pos,
				'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
		}
		#get_log
		my $aa =$log_signal_db->get_collection($node)->find_one({'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
		$answer->[$day_index]{log} = 
			$log_signal_db->get_collection($node)->
				count({'tempID'=>$log_tempID,
				'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
		#get_job
		$answer->[$day_index]{job} = 
			$job_db->get_collection($node)->
				count({'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
	}
}
get '/nodes_abstract' => sub {
	content_type 'application/json';
	my $target;
	my $start_time = param 'start_time';
	my $day_count = param 'day_count';
	my $sar_pos = param 'sar_pos';
	my $sar_neg = param 'sar_neg';
	my $log_db = param 'log_db';
	my $log_tempID = param 'log_tempID';
	my %answer:shared;
	my $index = 0;
	foreach my $node(@nodes) {
		$index ++;
		my %content:shared;
		%content = (sar=>0,log=>0,job=>0);
		$answer{$node} = \%content;
	}
	my @read_pool;
	my $read_queue = Thread::Queue->new();
	$read_queue->enqueue(@nodes);
	my $threads_num = 40;
	foreach my $thread_id(0..($threads_num-1)) {
		push @read_pool,threads->create(\&get_node_abstraction,\%answer,$read_queue,
						$start_time,$day_count,$sar_pos,$sar_neg,$log_db,$log_tempID);
	}
	$read_queue->end;
	foreach (@read_pool){
		$_->join;
	}
	return to_json(\%answer);
};
sub get_node_abstraction {
	my ($answer,$read_queue,$start_time,$day_count,$sar_pos,$sar_neg,$log_db,$log_tempID)= @_;
	$log_tempID = $log_tempID +0;
	$sar_pos += 0;
	$sar_neg += 0;
	my $sar_signal_db = MongoDB::Connection->new->get_database('Sar_signal');
	my $log_signal_db = MongoDB::Connection->new->get_database($log_db);
	my $job_db = MongoDB::Connection->new->get_database('Job_signal');
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
			$job_db->get_collection($node)->
				count({'logTime'=>{'$gte'=>$start_time,'$lte'=>$end_time}});
	}
}
Dancer->dance;
