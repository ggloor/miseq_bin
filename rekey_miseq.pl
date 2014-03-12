#!/usr/bin/env perl -w
use strict;
my $samples = $ARGV[0];
my $tabbed = $ARGV[1];

my %bc;
open (IN, "< $samples") or die;
	while(my $l =<IN>){
		chomp $l;
		my @l = split/\t/, $l;
		my $lbc = uc($l[0]);
		my $temp = uc($l[1]);
		my $rbc = reverse($temp);
		$rbc =~ tr/ACGT/TGCA/;
		my $bc = "$lbc-$rbc";
		$bc{$bc}=$l[2];
	}
close IN;

open (IN,  "< $tabbed") or die;
	while(my $l = <IN>){
		chomp $l;
		my @l = split/\t/, $l;
		my $bc = "$l[1]-$l[5]";
		if(exists $bc{$bc}){
			$l[5] = $bc;
			$l[1] = $bc{$bc};
			my $o = join("\t", @l);
			print "$o\n";
		}
	}
close IN;
