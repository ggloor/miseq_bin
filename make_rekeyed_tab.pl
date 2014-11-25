#!/usr/bin/env perl -w
use strict;

# put data into rekeyed_tab.txt format
# read_id ID Lpri seq Rpri barcode quality
# first argument is path
# second argument is file name
# output is by command redirection

my $count = 0;
my $lpri = "GTGCCAGCMGCCGCGGTAA";
my $rpri = "GGACTACHVGGGTWTCTAAT";
my $data;

my @bc = split/_/, $ARGV[1];
my $file = "$ARGV[0]/$ARGV[1]";

open (IN, "< $file") or die;
	while(my $l = <IN>){
		chomp $l;
		if ($count % 4 == 0){
			print "$data\n" if $count > 0;
			$data = "$l\t$bc[0]\t$lpri\t";
		}elsif($count % 4 == 1){
			$data .= "$l\t$rpri\t$bc[0]\t";		
		}elsif($count %4 == 3){
			$data .= $l;
		}
		$count++;
	}
close IN;
#print the last sequence 
print "$data\n"