#!/usr/bin/env perl -w
use strict;

# extract barcoded fastq format into fastq files per group
# need forward fastq, reverse fastq and samples file as input
# output is to two fastq files named group_r1.fastq group_r2.fastq
#
# barcodes and primers are NOT stripped
#
# argument list is:
# 0 samples.txt
# 1 forward fastq
# 2 reverse fastq
# 3 group
my %samples;
my $bclen = 8;
my $group = $ARGV[3];

# open samples.txt file and make a hash of forwardbc-reversebc  with value sampleID
# also get the barcode length
open (IN, "< $ARGV[0]") or die "$!\n";
	while(my $l = <IN>){
		chomp $l;
		my @l = split/\t/, $l;
		my $bc = join("-", uc($l[0]), uc($l[1]));
        if ($bc =~ /^[ACGT]/){
        	$samples{$bc} = "";
    		$bclen = length($l[0]);
		}
	}
close IN;

my $out1 = $group . "_1.fastq";
my $out2 = $group . "_2.fastq";

my $c = 0; my $dataL = my $dataR; my $keep = "F";
#open forward fastq and reverse fastq
open (IN1, "< $ARGV[1]") or die "$!]n";
open (IN2, "< $ARGV[2]") or die "$!\n";
open (OUT1, "> $out1") or die "$!\n";
open (OUT2, "> $out2") or die "$!\n";
	while(my $l1 = <IN1>){
		my $l2 = <IN2>;
		chomp $l1; chomp $l2;
		if ($c % 4 == 0 ) { #def line
			if ($keep ne "F"){
				print OUT1 $dataL;
				print OUT2 $dataR;
			}
			#empty the variables
			$keep = "F";
			$dataL = "$l1\n";
			$dataR = "$l2\n";
			#added check for line length gg, march 3, 2015
		}elsif($c % 4 == 1 ){ #seq line

			my $bc = join( "-", substr($l1, 4,$bclen), substr($l2, 4,$bclen) );
			#print "$c $bc \n$l1\n$l2\n";
			if (exists $samples{$bc}){
				$keep = $bc ;
				$dataL .= $l1 . "\n";
				$dataR .= $l2 . "\n";
			}
		}elsif($c % 4 == 2 ){ #second def line
			$dataL .= "+\n";
			$dataR .= "+\n";
		}elsif($c % 4 == 3 && $keep ne "F") { #qscore
			$dataL .= $l1 . "\n";
			$dataR .= $l2 . "\n";
		}
		$c++;

#	if ($c > 100000){
#		last;
#		close IN1; close IN2;
#	}
	}
close OUT1; close OUT2;
close IN1; close IN2;
