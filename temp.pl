#!/usr/bin/perl -w
use Data::Dumper;
open FIN,"<$ARGV[0]";
while(my $line = <FIN>){
	my @terms = ();
	@temrs = split (/\s/,$line);
	print $line;
	print ":::".Dumper(@terms).":::\n";
	defined $terms[6] or $terms[6] = -1;
	print "{id1:'$terms[0]',id2:'$terms[1]',pos:$term[4],neg:$term[6]}\n";
}
