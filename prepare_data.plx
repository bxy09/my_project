#!/usr/bin/perl -w
use warnings;
open CONFIG, "<config/sys.config";
my %config; 
while(<CONFIG>) {
    chomp;
    my($a,$b)= m/^(\S+)\s*=\s*([\S|\s]*\S)/;
    $config{$a} = $b;
}
chomp(my $localpath = `pwd`);
$localpath .='/';
if($config{"IS_PROC_TERMLOG"} eq "true") {
	system  "bin/prepare_job_assignment_log",
		$config{"DATASET_PATH"},$config{"TERM_LOG_PATH"};
}
if($config{"IS_PROC_ERRORLOG"} eq "true") {
	open FILE_LIST,">LsfErrorFilePath";
	print FILE_LIST $config{"ERROR_LOG_PATH"}.$_ 
		foreach(`ls $config{"ERROR_LOG_PATH"}`);
	close FILE_LIST;
	system "bin/prepare_lsf_error_log",$config{"DATASET_PATH"},
			"LsfErrorFilePath";
	system "rm LsfErrorFilePath";
}
if($config{"IS_PROC_SYSLOG"} eq "true") {
	open FILE_LIST,">SysLogFilePath";
	print FILE_LIST $config{"SYS_LOG_PATH"}.$_ 
		foreach(`ls $config{"SYS_LOG_PATH"}`);
	close FILE_LIST;
	system "bin/prepare_sys_log",$config{"DATASET_PATH"},
			"SysLogFilePath";
	system "rm SysLogFilePath";
}
if($config{"IS_PROC_SARLOG"} eq "true") {
	system  "./src/loader/sar_log/main.plx",
		$config{"SAR_LOG_PATH"};
}
#system("cd src/Hymal;sbt AnalyserLayer/run");
print "end\n";

