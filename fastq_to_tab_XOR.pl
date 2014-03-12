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

#convert fastq to tabbed format
#requires knowing the primer lengths beforehand
#works if the primer has already been identified by get_v9.pl

#my $Lplen = 15; my $Rplen = 20; #primer lengths for v9
#these are the primers for v6 
my $maxLdist = 1; my $maxRdist = 1; #maximum number of mismatches with primer sequence
if (@ARGV < 2) {print "overlap file and variable region needed\n"};

my $Lp = my $Rp = my $Lplen = my $Rplen;
if (uc($ARGV[1]) eq "V6"){
	$Lp = "CXACGCGAXGAACCTTACC"; $Rp = "GTCGTCAGCTCGTGTXGT"; #primer lengths for v6
	$Lplen = 19; $Rplen = 18;
}elsif (uc($ARGV[1]) eq "V9"){
	$Lp = "TTGTACACACCGCCC";
	$Rp = "CCTTCXGCAGGTTCACCTAC";
	$Lplen = 15; $Rplen = 20;
}elsif (uc($ARGV[1] eq "V9_b")){
	$Lp = "CCCTGCCXTTTGTACACAC";
	$Rp = "GTAGGTGAACCTGCXGAAGG";
	$Lplen = 19; $Rplen = 20;
}elsif(uc($ARGV[1] eq "28S")){
	$Lp = "AACXGCGAGTGAAGXGGGA";
	$Rp = "CAAGTACCGTGAGGGAAAGA";
	$Lplen = 19; $Rplen = 20;
}elsif(uc($ARGV[1] eq "V4")){
	$Lp = "CCAGCXGCCGCGGTAA";
	$Rp = "ATTAGAXACCCXXGTAGTCC";
	$Lplen = 16; $Rplen = 20;
}elsif(uc($ARGV[1] eq "V4EMB")){
	#$Lp = "GTGCCAGCXGCCGCGGTAA";
	#$Rp = "ATTAGAXACCCXXGTAGTCC";
	$Lp = "GTGCCAGCXGCCGCGGTAA";
	$Rp = "ATTAGAXACCCXXGTAGTCC";
	$Lplen = 19; $Rplen = 20;
	$maxLdist = 2; $maxRdist = 4; #allow one additional primer mismatch
}


my $counter = 0; my $r1 = ""; my $keep = "N";
open (IN, "< $ARGV[0]") or die;
	while(my $l = <IN>){
		chomp $l;
		if ($counter % 4 == 0 ){
			
			print "$r1\n" if $keep eq "Y";
									
			$r1 = ""; $keep = "N";
			$counter++;
			$r1 .= $l;
			
		}elsif($counter % 4 == 1){
			my $Lpseq = substr($l,12,$Lplen);
			my $Rpseq = substr($l,-(12 + $Rplen),$Rplen);
			
			#count the number of differences between the primer and the sequence
			my $ldist = ($Lpseq ^ $Lp) =~ tr/\000//c;
			my $rdist = ($Rpseq ^ $Rp) =~ tr/\000//c;
			
			if ($ldist <= $maxLdist && $rdist <= $maxRdist){
				$keep = "Y";
				my $len = length($l);	
			
#				my $lv = $l;
#				$lv =~ (m/$Lp/g);
#				my $lpos = pos $lv;
#				my $lbc_end = $lpos - $Lplen;
#			
#				my $rv = $l;
#				$rv =~ (m/$Rp/g);
#				my $rpos = pos $rv;
#			
				my $lbc = substr($l, 0,12);
				my $lp = substr($l, 12, $Lplen);

				my $rp = substr($l, -(12 + $Rplen),  $Rplen);
				my $rbc = substr($l, -12, 12 );
			
				my $seq = substr($l, (12 + $Lplen), (12 - 12 - $Rplen));  

				$r1 .= "\t$lbc\t$lp\t$seq\t$rp\t$rbc";
			}
			$counter++;
		}elsif($counter % 4 == 3) { #quality score line
			$r1 .= "\t$l";
			$counter++;
		}else{
			$counter++;
		}
	#if ($counter > 500000){ close IN; exit;}
	}
close IN;
