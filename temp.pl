#!/usr/bin/perl -w
use Data::Dumper;
open FIN,"<$ARGV[0]";
while(my $line = <FIN>){
	my ($a,$b,$pos,$neg) = $line =~m/^(\S+)\s+(\S+)\s+\d+\s+(\d+)\s+(\d+)/;
	unless(defined $neg) {
		$neg = -1;
		($a,$b,$pos) = $line =~m/^(\S+)\s+(\S+)\s+\d+\s+(\d+)/;
	}
	print "{id1:'$a',id2:'$b',pos:$pos,neg:$neg},\n";
}
