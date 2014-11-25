#!/usr/bin/env perl -w
use strict;

# revert an individual rekeyed_tab_file.txt to fastq
# used to send an overlapped.fastq file to collaborators

open (IN, "< $ARGV[0]") or die;
	while(my $l = <IN>){
		chomp $l;
		my @l = split/\t/, $l;
		my @bc = split/-/, $l[5];
		my $seq = "TTTT" . $bc[0] . $l[2] . $l[3] . l[4] . $bc[1] . "TTTT";
		print
	}
close IN;