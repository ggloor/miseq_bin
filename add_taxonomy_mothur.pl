#!/usr/bin/env perl -w
use strict;

# open the parsed gg output file and build a look-up table
# autodetect if samples were bootstrapped

my %tax; my %bs;
my $bootstrapped = my $count = 0;
open (IN, "< $ARGV[0]") or die"could not read $ARGV[0] $!\n";
	while(my $l = <IN>){
		chomp $l;
		$bootstrapped = 1 if $l =~ /\(\d+\)/;
		my @l = split/\t/, $l;
		my @ll = split/\|/, $l[0];
		if ($bootstrapped == 1){
			$count++ while $l =~ /\(\d+\)/g; #get the number of matches
			my @bsnum = split/\(/, $l; # split on the first bracket
			my @n = split/\)/, $bsnum[$count]; #split on the second bracket at the last match
			$bs{$ll[5]} = $n[0]; # get the bootstrap, assumes bootstraps above are greater
			$l[1] =~ s/\(\d+\)//g; # remove the bootstrap values
			$tax{$ll[5]} = $l[1]; #key is otu number
			#print "$count $n[0] $l\n"; # works
			$count = 0;
		}else{
			$tax{$ll[5]} = $l[1]; #key is otu number
		}
	}
close IN;

#open the table and add taxonomy to each OTU
open (IN, "< $ARGV[1]") or die "could not read $ARGV[0] $!\n";
	while(my $l = <IN>){
		my @l = split/\t/, $l;
		chomp $l;
		if ($l =~ /^#OTU/){
			print "$l\ttaxonomy\n" ;
		}elsif ($l =~ /^#/){
			print "$l\n";
		}elsif ($l !~ /^#/){
			my @l = split/\t/, $l;
			my $taxonomy = "NA;NA;NA;NA;NA;NA;NA";
			$taxonomy = $tax{$l[0]} . "|$bs{$l[0]}" if $tax{$l[0]} && $bootstrapped == 1;
			$taxonomy = $tax{$l[0]} if $tax{$l[0]} && $bootstrapped == 0;
			print "$l\t$taxonomy\n";
		}
	}
close IN;

