#!/usr/bin/env perl -w
use strict;

# read the typescript_copy.txt file, build paths to valid overlapping files
# use pandaseq to generate the overlap
open (IN, "< $ARGV[0]") or die "$!\n";
	while(my $l = <IN>){
		chomp $l;
		if( $l =~ /lines:/ && $l !~ /unmatched/){
			my @l = split/[\/_]/, $l;
			my $left = "$l[0]/R1/$l[2]" . "_R1.fastq";
			my $right = "$l[0]/R2/$l[2]" . "_R2.fastq";		
			my $out = "overlapped/$l[0]/$l[2]" . "_ol.fastq";
			my $log = "overlapped/$l[0]/$l[2].log";
					
			#do the overlap
			system("pandaseq -F -f  $left -r  $right -w $out -G $log");		
		}
	}
close IN;

