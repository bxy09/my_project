#!/usr/bin/perl -w
use warnings;
use strict;
require MongoDB;
require MongoDB::OID;
use threads;
use threads::shared;
use Thread::Queue;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
use JSON;
#########################################
eval "use ${_}" # no Any::Moose::load_class becase the namespaces already have symbols from the xs bootstrap
  for qw/MongoDB::Database MongoDB::Cursor MongoDB::OID MongoDB::Timestamp/;
my @nodes;
share(@nodes);
read_nodelist();

my @signals = ();
get_signals();
sub get_signals{
	my @signal_clusters = (
						{db=>'Job_signal',num=>8},
						{db=>'Sar_signal',num=>181},
						{db=>'lim',num=>7},
						{db=>'pim',num=>1},
						{db=>'res',num=>15},
						{db=>'sbatchd',num=>20},
						{db=>'messages',num=>2}
						);
	foreach my $signal_cluster(@signal_clusters){
		my $num = $signal_cluster->{num};
		my $db_handle = MongoDB::Connection->new()->get_database($signal_cluster->{db});
		#ensure_index
		foreach my $node(@nodes) {
			$db_handle->get_collection($node)->ensure_index({'tempID'=>1,'logTime'=>1});
		}
		foreach (0..($num-1)) {
			push @signals,{tempID=>$_,db=>$signal_cluster->{db}};
		}
	}
}
#prepare
my $cov_mat= [];
my $count = [];
foreach my $i(0..$#signals) {
	push @$count,0;
	my @row:shared;
	foreach my $j(0..$#signals) {
		push @row,0;
	}
	push @$cov_mat,\@row;
}
my $all_records;
my $j_queue = Thread::Queue->new();
my $read_queue = Thread::Queue->new();
my $read_back_queue = Thread::Queue->new();
my $threads_num = 40;
my @read_pool;
my @calc_pool;
foreach my $thread_id(0..($threads_num-1)) {
	push @read_pool,threads->create(\&read_records,$thread_id);
}
#foreach node
foreach my $node(@nodes) {
	print "start read $node\n";
#read all records
	$read_back_queue->pending == 0 or die "read_back_queue is not clean!".$read_back_queue->pending;
	foreach my $i(0..$#signals) {
		$read_queue->enqueue("$node $i");
	}
	my $read_num = 0;
	while(my ($i,$num) = $read_back_queue->dequeue(2)) {
		$read_num++;
		if($num !=0) {
			my @i_records = $read_back_queue->dequeue($num);
			$count->[$i] += scalar @i_records;
			$all_records->{$i} = \@i_records;
		} else {
			$all_records->{$i} = [];
		}
		if($read_num == scalar @signals) {
			last;
		}
	}
	print "after read $node\n";
	print "wait for last calc\n";
	while($j_queue->pending!=0) {
		sleep 1;
	}
	foreach (@calc_pool) {
		if($_->is_joinable) {
			$_->join;
		}
	}
#start calc
	print "start calc $node\n";
	foreach my $i(0..$#signals) {
		foreach my $j (0..$#signals) {
			$j_queue->enqueue("$i $j");
		}
	}
	foreach (1..$threads_num) {
		push @calc_pool,threads->create(\&count_cov,$_);
	}
}
while($j_queue->pending!=0) {
	sleep 1;
}
foreach (@calc_pool) {
	if($_->is_joinable) {
		$_->join;
	}
}
$read_queue->end;
foreach (@read_pool){
	$_->join;
}
#print
my $big_ratio_couple = [];
my $double_big_ratio = [];
foreach my $i(0..$#signals){
	printf "sig:%10s count:%10d ","$signals[$i]->{db}:$signals[$i]->{tempID}",$count->[$i];
	foreach my $j(0..$#signals){
		if(print_cov_cell($i,$j)>0.8 and $cov_mat->[$i][$j] > 20) {
			if(get_cov_cell($j,$i) > 0.8) {
				if($j>$i) {
					push @$double_big_ratio,[$i,$j];
				}
			} else {
				push @$big_ratio_couple,[$i,$j];
			}
		}
	}
	print "\n";
}
print "big::::::\n";
foreach my $couple (@$big_ratio_couple) {
	my ($i,$j) = @$couple;
	printf "sig:%10s count:%10d ","$signals[$i]->{db}:$signals[$i]->{tempID}",$count->[$i];
	printf "sig:%10s count:%10d ","$signals[$j]->{db}:$signals[$j]->{tempID}",$count->[$j];
	print_cov_cell($i,$j);
	printf " ";
	print_cov_cell($j,$i);
	print "\n";
}
print "double::::::\n";
foreach my $couple (@$double_big_ratio) {
	my ($i,$j) = @$couple;
	printf "sig:%10s count:%10d ","$signals[$i]->{db}:$signals[$i]->{tempID}",$count->[$i];
	printf "sig:%10s count:%10d ","$signals[$j]->{db}:$signals[$j]->{tempID}",$count->[$j];
	print_cov_cell($i,$j);
	printf " ";
	print_cov_cell($j,$i);
	print "\n";
}
#####################################################
sub read_records {
	my $thread_id = shift @_;
	my $pair;
	while(defined ($pair = $read_queue->dequeue())) {
		my ($node,$i) = split /\s+/,$pair;
		#print "read thread $thread_id get work node:$node i:$i\n";
		my $i_handle = MongoDB::Connection->new()->get_database($signals[$i]->{db});
		my $i_cursor= $i_handle->get_collection($node)->find({'tempID'=>$signals[$i]->{tempID}},{'logTime'=>1})->sort({'logTime'=>1});
		my @node_records_vec;
		my $time = 0;
		my $last_trash_time = 0;
		while(my $i_record = $i_cursor->next()) {
			if($i_record->{logTime}-$time<5*60) {
				$last_trash_time = $i_record->{logTime};
			} else {
				if($last_trash_time != 0) {
					if($i_record->{logTime}-$time>6*60) {
						push @node_records_vec,$last_trash_time;
					}
					$last_trash_time = 0;
				}
				$time = $i_record->{logTime};
				push @node_records_vec,$time;
			}
		}
		#print "i:$i produce ".scalar(@node_records_vec)."\n";
		$read_back_queue->enqueue(($i,scalar(@node_records_vec),@node_records_vec));
	}
}
sub bsearch_num_pos {
    my ( $target, $aref ) = @_;
    my ( $low, $high ) = ( 0, scalar @{$aref} );
    while ( $low < $high ) {
        my $cur = int( ( $low + $high ) / 2 );
        if ( $target > $aref->[$cur] ) {
            $low = $cur + 1;    # too small, try higher
        }
        else {
            $high = $cur;       # not too small, try lower
        }
    }
    return $low;
}
sub count_cov {
	my ($thread_no) = @_;
	#print "thread $thread_no init!!\n";
	my $pair;
	while(defined ($pair = $j_queue->dequeue_nb())) {
		my ($i,$j) = split /\s+/,$pair;
		if($j == $i) {next;}
		#print "thread $thread_no get j:$j i:$i $signals[$i]->{db}\n";
		my $ret_val = 0;
		defined $all_records->{$j} and scalar @{$all_records->{$j}} > 0 or next;
		defined $all_records->{$i} and scalar @{$all_records->{$i}} > 0 or next;
		my $j_list = $all_records->{$j};
		foreach my $time(@{$all_records->{$i}}) {
			#在ilog的上下三十分钟内是否存在jlog
			my $index = &bsearch_num_pos($time-60*60,$j_list);
			$index < scalar @$j_list or next;
			$j_list->[$index] <= $time+60*60 or next;
			$ret_val++;
		}
		$cov_mat->[$i][$j] += $ret_val;
	}
	#print "thread $thread_no exit!!\n";
}
sub get_cov_cell{
	my ($i,$j) = @_;
	my $ratio = 0;
	if($count->[$i]==0) {
		$ratio = 0;
	}else {
		$ratio = $cov_mat->[$i][$j]/$count->[$i];
	}
	return $ratio;
}
sub print_cov_cell{
	my ($i,$j) = @_;
	my $ratio = 0;
	if($count->[$i]==0) {
		$ratio = 0;
	}else {
		$ratio = $cov_mat->[$i][$j]/$count->[$i];
	}
	printf "%10d/%1.4f ",$cov_mat->[$i][$j],$ratio;
	return $ratio;
}
sub read_nodelist{
	my $node_list_path = shift @ARGV;
	open NODE,"<$node_list_path" or die "can't open nodelist:$node_list_path";
	while(<NODE>) {
		s/\r\n//;
		push @nodes,$_;
	}
}
