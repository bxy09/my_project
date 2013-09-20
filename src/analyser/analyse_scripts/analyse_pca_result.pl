#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
scalar @ARGV == 2 or die "parament error!";
open CSV,"<$ARGV[0]";
open FEATURE_NAME,"<$ARGV[1]";
my $mat = [];
while(<CSV>){
	my @line = split ",";
	my @line_with_index = ();
	foreach my $index(0..$#line) {
		push @line_with_index,{val=>$line[$index],index=>$index};
	}
	@line_with_index = reverse sort{abs($a->{val})<=>abs($b->{val})} @line_with_index;
	push @$mat,\@line_with_index;
}
close(CSV);
my @feature_name_list = ();
while(<FEATURE_NAME>) {
	chomp;
	print $_."\n";
	push @feature_name_list,$_;
}
scalar @feature_name_list == scalar @$mat or die "logic error";
my $comp_index = 0;
foreach my $component(@$mat){
	print "component $comp_index\n";
	$comp_index++;
	foreach my $index(0..100) {
		my $value = $component->[$index]{val};
		abs($value) >= 0.1 or $index <4 or last;
		my $name_index = $component->[$index]{index};
		print "$feature_name_list[$name_index] $value\n";
	}
	$comp_index < 10 or last;
}

