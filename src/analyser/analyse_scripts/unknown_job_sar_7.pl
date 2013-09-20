use strict;
use MongoDB;
use MongoDB::OID;
use Test::Parser::Sar;
use Data::Dumper;
use POSIX;
my $conn = MongoDB::Connection->new;
my $JobA_db = $conn->get_database('JobAssign');
my $JobA_col = $JobA_db->get_collection('JobAssign');
my $start_time = 1366819200;
my $end_time = $start_time +31*3600*24;
my $data = $JobA_col->find({'eventTime'=>{'$gte'=>$start_time},
	  	 'submitTime'=>{'$lte'=>$end_time},
	  	 'startTime'=>{'$lte'=>$end_time},"jStatus"=>32,"exitInfo"=>0});
my %users;
my $job_num1;
my $job_num2;
my $job_num3;
while (my $object = $data->next) {
	my $execHosts = $object->{execHosts};
	my $start_time = $object->{startTime};
	my $event_time = $object->{eventTime};
	my $submit_time = $object->{submitTime};
	my $user = $object->{userName};
	unless(defined $users{$user}) {
		$users{$user} = {'count'=>0,'in_sig_count'=>0,'around_sig_count'=>0};
	}
	$users{$user}->{count} ++;
	$job_num1++;
	$start_time = $object->{submitTime}if ($object->{submitTime} > $start_time);
	my $uniq_hosts = {};
	foreach (@$execHosts) {$uniq_hosts->{$_} = 1;}
	foreach my $node(keys %$uniq_hosts) {
		my $node_handle = MongoDB::Connection->new->get_database('Sar_signal')
		->get_collection($node);
		if($node_handle->count({'tempID'=>7,
		'logTime'=>{'$gte'=>$start_time,'$lte'=>$event_time}}) > 0) {
			$users{$user}->{in_sig_count} ++;
			$job_num2++;
			last;
		}
	}
	foreach my $node(keys %$uniq_hosts) {
		my $node_handle = MongoDB::Connection->new->get_database('Sar_signal')
		->get_collection($node);
		if($node_handle->count({'tempID'=>7,
		'logTime'=>{'$gte'=>$event_time-3600,'$lte'=>$event_time+3600}}) > 0) {
			$users{$user}->{around_sig_count} ++;
			$job_num3++;
			last;
		}
	}
}
foreach my $user(keys %users) {
	if($users{$user}->{count} > 100) {
		print "$user $users{$user}->{count} $users{$user}->{in_sig_count} $users{$user}->{around_sig_count}\n";
	}
}
print Dumper(\%users);
print "$job_num1 $job_num2 $job_num3\n";
