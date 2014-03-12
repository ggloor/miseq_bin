#!/usr/bin/env perl -w
use strict;

#keep only the primer-proximal nucleotides for barcodes
#this is compatible with other workflows
my $bclen = 6;
$bclen = $ARGV[1] if $ARGV[1]; #undocumented 
open (IN, "< $ARGV[0]") or die;
	while(my $l = <IN>){
		chomp $l;
		my @l = split/\t/, $l;
		if (length($l[1]) == 12 && length($l[5]) == 12){
			my $x = substr($l[1],(12 - $bclen));
			my $y = substr($l[5],0,$bclen);
			$l[1] = $x; $l[5] = $y;
			my $data = join("\t", @l);
			print "$data\n";
		}
	}
close IN;