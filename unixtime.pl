#!/usr/bin/perl -w
use POSIX;
if(@ARGV == 1) {
#unix -> time
	print localtime($ARGV[0]);
} else {
	my @start_time = (0,0,0,0,0,0);#年月日时分秒
	$ARGV[0] -= 1900;
	$ARGV[1] -= 1;
	@start_time = @ARGV;
	while(@start_time != 6){
		push @start_time,0;
	}
	print mktime($start_time[5],$start_time[4],$start_time[3],$start_time[2],$start_time[1],$start_time[0]);
}
