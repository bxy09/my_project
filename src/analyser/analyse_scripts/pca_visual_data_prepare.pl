use strict;
use warnings;
use Data::Dumper;
use JSON;
scalar(@ARGV) == 3 or die "parament error!";
open CSV_IN,"<$ARGV[0]";
open FEATURE_IN,"<$ARGV[1]";
open DATA_OUT,">$ARGV[2]";
my @feature_name_list = ();
while(<FEATURE_IN>) {
	chomp;
	push @feature_name_list,$_;
}
close(FEATURE_IN);
my $mat = [];
my $max_plus = 0;
my $max_minus = 0;
my $index = 0;
while(<CSV_IN>){
	my @line = split ",";
	my @out_line = ();
	foreach my $num (@line) {
		if($num ==0) {
			push @out_line,[0,0];
		} elsif($num >0) {
			push @out_line,[$num+0,0];
			$num < $max_plus or $max_plus = $num+0;
		} else {
			$num = -$num;
			push @out_line,[0,$num];
			$num < $max_minus or $max_minus = $num+0;
		}
	}
	push @$mat,{name=>$feature_name_list[$index],data=>\@out_line};
	$index ++;
}
close(CSV_IN);
scalar @feature_name_list == scalar @$mat or die "logic error";
print DATA_OUT "var all_data=";
my $out = {statics=>[[{cover=>$max_plus,num=>0}],[{cover=>$max_minus,num=>0}]],
						data=>$mat,data_name=>"cov"};
print DATA_OUT encode_json([$out]);
print DATA_OUT ";\n";
print DATA_OUT "var yname=";
print DATA_OUT encode_json(\@feature_name_list);
print DATA_OUT ";\n";
my @sub_data_name = qw/positive negative/;
print DATA_OUT "var sub_data_name =".encode_json(\@sub_data_name).";";
