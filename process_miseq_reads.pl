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

#replaces the former fastq_to_tab.pl, filter_barcodes.pl, and get_validtags.pl
#does all operations in one pass, rather than three through the data
#allows one mismatch within the primer sequence

#output is a tab formatted file that can be used for rekey_miseq.pl

#inputs:
# 1: primer sequence file, kept privately in bin, loaded automatically
# 2: $ARGV[0]: location of BIN file
# 3: $ARGV[1]: location of valid_tags file
# 4: $ARGV[2]: pandaseq overlapped fastq file
# 5: $ARGV[3]: variable region name
# 6: $ARGV[4]: barcode length, default 8

#get the primer information matching the requested primer
#[0] Lseq with X instead of mismatches
#[1] Rseq with X instead of mismatches
#[2] L length
#[3] R length
#[4] allowed L mismatches
#[5] allowed R mismatches
#[6] Lseq 
#[7] Rseq 

my @primerinfo = get_primer_info( $ARGV[0], $ARGV[3]);
foreach(@primerinfo){
	print "$_\n";
}

#get the list of valid barcode pairs and store in a hash
my %vtag = pop_tag();

my $bclen = 8;
$bclen = $ARGV[4] if $ARGV[4];

#now get and print the data
my $counter = 0; my $r1 = my $bc = ""; my $keep = "N";
open (IN, "< $ARGV[2]") or die;
	while(my $l = <IN>){
		chomp $l;
		if ($counter % 4 == 0 ){
			
			print "$r1\n" if ( $keep eq "Y" && exists($vtag{$bc}) );
									
			$r1 = $bc = ""; $keep = "N";
			$counter++;
			$r1 .= $l;
			
		}elsif($counter % 4 == 1){
			my $Lpseq = substr($l,12,$primerinfo[2]);
			my $Rpseq = substr($l,-(12 + $primerinfo[3]),$primerinfo[3]);
			
			#count the number of differences between the primer and the sequence
			my $ldist = ($Lpseq ^ $primerinfo[0]) =~ tr/\000//c;
			my $rdist = ($Rpseq ^ $primerinfo[1]) =~ tr/\000//c;
			
			if ($ldist <= $primerinfo[4] && $rdist <= $primerinfo[5]){
				$keep = "Y";
				my $len = length($l);	
			
				my $lbc = substr($l, (12 - $bclen),12);
				my $lp = substr($l, 12, $primerinfo[2]);

				my $rp = substr($l, -(12 + $primerinfo[3]),  $primerinfo[3]);
				my $rbc = substr($l, -12, $bclen );
			
				my $seq = substr($l, (12 + $primerinfo[2]), (12 - 12 - $primerinfo[3]));  

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

#WORKS
sub pop_tag{
	my %tags;
	open (IN, "< $ARGV[1]") or die "$!\n";
		while(my $l = <IN>){
			chomp $l;
			$tags{$l} = "" if $l !~ /^BC_/;
		}
	close IN;
	return %tags;
}

#WORKS
sub get_primer_info {
	my @data = ();
	open (IN, "< $_[0]/primer_sequences.txt") or die "$!\n";
		while(my $l = <IN>){
			chomp $l;
			my @l = split/\t/, $l;
			if ($l[0] eq $_[1]){
				#change redundant segments to X
				( $data[0] = $l[1] ) =~ s/\[.{2,3}\]/X/g;
				( $data[1] = $l[2] ) =~ s/\[.{2,3}\]/X/g;
				$data[2] = length($data[0]);
				$data[3] = length($data[1]);
				$data[4] = scalar(split/X/, $data[0]); #one more mismatches than redundant positions
				$data[5] = scalar(split/X/, $data[1]);
				$data[6] = $l[1];
				$data[7] = $l[2];
			}
		}
	close IN;
	return(@data)
}
