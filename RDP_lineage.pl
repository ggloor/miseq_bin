#!/usr/bin/env perl -w 
use strict;

my %lineage;

print "need the RDP classifier output file\n" if !$ARGV[0];

print "need OTU table in QIIME format\n" if !$ARGV[1];

exit if (!$ARGV[0] or !$ARGV[1]);

my $rdp_file = $ARGV[0];
my $otu_file = $ARGV[1];

my $parse = 1;
open (IN, "< $rdp_file") or die;
	while(defined(my $l = <IN>)){
		chomp $l;
		$l =~ s/[" ]//g;
		if ($parse == 1 && $l ne ""){
			my @l = split/\t/, $l;
			my @o = split/\|/, $l[0];
		#this needs to be set for the accession id format
			my $OTU = $o[5];
			#$OTU = $l[0];
			
			my @lin = split/\|/, $l[1];
			
			$lineage{$OTU} = join(";", $lin[3],  $lin[5], $lin[7],  $lin[9],  $lin[11],  $lin[13]) if $lin[13];
			$lineage{$OTU} = "unclassified;unlassified;unclassified;unclassified;$lin[3];uclassified" if !$lin[13];
			
		#print "$OTU $lineage{$OTU}\n";
		
		}
		$parse = 1 if $l =~ /^Details/;
	}
close IN;

open (IN, "< $otu_file") or die;
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/\t/, $l;
		if ($l =~ /^#OTU/){
			print "$l\ttaxonomy\n";
		}elsif($l =~ /^#meta/){
			print "$l\n";
		}else{
			print "$l\t$lineage{$l[0]}\n";	
		}
	}
close IN;