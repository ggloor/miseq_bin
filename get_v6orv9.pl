#!/usr/bin/env perl -w
use strict;
#######
# This software is Copyright 2013 Greg Gloor and is distributed under the 
#    terms of the GNU General Public License.
#
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#    along with this program. It should be located in gnu_license.txt
#    If not, see <http://www.gnu.org/licenses/>.
########

#############
#filter for the good left and right end V6 or v9 reads from the fastq files
#
#filtered for: 	proper left and right side primers
#				neither read contains an N character
#				places the reads so that the left primer is always in read1
#				and the right primer is always in read2
#				simplifies downstream processing
#
#outputs 2 fastq files v6_read1.fastq, v6_read2.fastq
#############

if (@ARGV != 3){print "enter runs 1 and 2 and V6, V9 or V9b\n"; exit;}

my $read1 = $ARGV[0]; my $read2 = $ARGV[1];

my $v6lp = "C[AT]ACGCGA[AG]GAACCTTACC";
my $v6rp = "AC[AG]ACACGAGCTGACGAC";

my $v9lp = "TTGTACACACCGCCC";
my $v9rp = "CCTTC[TC]GCAGGTTCACCTAC";

my $v9lpb = "CCCTGCC[ACT]TTTGTACACAC";
my $v9rpb = "GTAGGTGAACCTGC[GA]GAAGG";

#forward
my $lp = $v6lp if uc($ARGV[2]) eq "V6";
my $rp = $v6rp if uc($ARGV[2]) eq "V6";

$lp = $v9lp if uc($ARGV[2]) eq "V9";
$rp = $v9rp if uc($ARGV[2]) eq "V9";

$lp = $v9lpb if uc($ARGV[2]) eq "V9b";
$rp = $v9rpb if uc($ARGV[2]) eq "V9b";

my $outfile1 = $ARGV[2] . "_read1.fastq";
my $outfile2 = $ARGV[2] . "_read2.fastq";

my $counter = 0;
my $r1 = my $r2 = ""; my $tf = 1; my $rc = 1;
#generate V6 only fastq files
open (IN1, "< $read1") or die;
open (IN2, "< $read2") or die;

open (OUT1, "> $outfile1") or die;
open (OUT2, "> $outfile2") or die;

	while(my $l1 = <IN1>){ #read in each line of read 1
		my $l2 = <IN2>;	#read in each line of read 2
		
		#
		if ($counter % 4 == 0){
			if ($tf == 0){
				print OUT1 $r1;
				print OUT2 $r2;
				$r1 = $r2 = "";
			}else{
				$r1 = $r2 = "";			
			}
			$tf = 1;
			$rc = 1;
			$counter++;
			$r1 .= $l1;
			$r2 .= $l2;
		}elsif($counter % 4 == 1){			
			#forward
			if ($l1 =~  /$lp/ && $l2 =~ /$rp/){
				$tf = 0;
				$r1 .= $l1;
				$r2 .= $l2;
			}elsif ($l2 =~  /$lp/ && $l1 =~ /$rp/){
				$tf = 0 ;
				$rc = 0;
				$r1 .= $l2;
				$r2 .= $l1;
			}else{
				$r1 .= $l1;
				$r2 .= $l2;
			}
			#test for good reads			
			$tf = 1 if ($l1 =~ /N/ or $l2 =~ /N/);		
			$counter++;
		}else{
			if ($rc == 0){
				$r1 .= $l2;
				$r2 .= $l1;
			}else{
				$r1 .= $l1;
				$r2 .= $l2;			
			}
			$counter++;
		}
		
		if ($counter > 10000){
			close IN1;
			close IN2;
			exit;
		
		}
	}
close OUT1;
close OUT2;
close IN1;
close IN2;
