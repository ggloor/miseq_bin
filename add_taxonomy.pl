#!/usr/bin/env perl -w
use strict;

#open the parsed gg output file and build a look-up table
my %tax;
open (IN, "< $ARGV[0]/$ARGV[1]") or die"$!\n";
	while(my $l = <IN>){
		chomp $l;
		my @l = split/\t/, $l;
		my @ll = split/\|/, $l[0];
		$tax{$ll[5]} = $l[2];
	}
close IN;

#open the table and add taxonomy to each OTU
open (IN, "< $ARGV[0]/$ARGV[2]") or die"$!\n";
	while(my $l = <IN>){
		my @l = split/\t/, $l;
		chomp $l;
		print "$l\n" if ($l =~ /^#meta/);
		print "$l\ttaxonomy\n" if ($l =~ /^#OTU/);
		if ($l !~ /^#/){
			my @l = split/\t/, $l;
			my $taxonomy = "undefined;unknown;unknown;unknown;unknown;unknown;unknown;unknown";
			$taxonomy = $tax{$l[0]} if $tax{$l[0]};
			print "$l\t$taxonomy\n";
		}
	}
close IN;

