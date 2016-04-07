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

#replaces the former fastq_to_tab.pl, filter_barcodes.pl, get_validtags.pl and rekey_miseq.pl
#does all operations in one pass, rather than three through the data
#allows one mismatch within the primer sequence

#output is a tab formatted rekeyed text file suitable for group_gt1.pl

#inputs:
# 1: primer sequence file, kept privately in bin, loaded automatically
# 2: $ARGV[0]: location of BIN file
# 3: $ARGV[1]: location of samples.txt file
# 4: $ARGV[2]: location of pandaseq overlapped fastq file
# 5: $ARGV[3]: variable region name
# 6: $ARGV[4]: barcode length, default 8
# 7: $ARGV[5]: additional mismatches allowed, default 0
# 8: $ARGV[6]: experiment name from the samples.txt file
# 8: $ARGV[7]: output fastq (F) or rekeyed_tab_file.txt (T)

my $additional_mismatches = 1; $additional_mismatches = $ARGV[5] if $ARGV[5] && $ARGV[5] < 3;
if ($ARGV[5] >= 3){ print "too many mismatches, only using a total of 3"; $additional_mismatches = 3; }

#@primerinfo contains the following:
#[0] Lseq with X instead of mismatches
#[1] Rseq with X instead of mismatches
#[2] L length
#[3] R length
#[4] allowed L mismatches
#[5] allowed R mismatches
#[6] Lseq
#[7] Rseq

my @primerinfo = get_primer_info( $ARGV[0], $ARGV[3]);

#get the list of valid barcode pairs and store in a hash
my %vtag = pop_tag( $ARGV[1], $ARGV[6]);
#test the output. Works
#my @test = keys(%vtag); foreach(@test){print "$_\n";} exit;

my $bclen = 8;
$bclen = $ARGV[4] if $ARGV[4];

#now get and print the data
my $counter = 0; my $r1 = my $bc = ""; my $keep = "N"; my $fastq;
open (IN, "< $ARGV[2]") or die;
	while(my $l = <IN>){
		chomp $l;
		if ($counter % 4 == 0 ){

			print "$r1\n" if ( $keep eq "Y" && exists($vtag{$bc}) && $ARGV[7] eq "T");
			print "$fastq" if ( $keep eq "Y" && exists($vtag{$bc}) && $ARGV[7] eq "F");

			$r1 = $fastq = $bc = ""; $keep = "N";
			$counter++;
			$r1 .= $l;
			$fastq = "$l\n";

		}elsif($counter % 4 == 1){
			my $Lpseq = substr($l,$bclen+4,$primerinfo[2]);
			my $Rpseq = substr($l,-($bclen+4 + $primerinfo[3]),$primerinfo[3]);
			$fastq .= "$l\n";
			#count the number of differences between the primer and the sequence
			my $ldist = ($Lpseq ^ $primerinfo[0]) =~ tr/\000//c;
			my $rdist = ($Rpseq ^ $primerinfo[1]) =~ tr/\000//c;

			if ($ldist <= $primerinfo[4] && $rdist <= $primerinfo[5]){
				$keep = "Y";
				my $len = length($l);

				my $lbc = substr($l, ($bclen+4 - $bclen),$bclen); #4 because the padding sequence is 4N
				my $lp = substr($l, $bclen+4, $primerinfo[2]);

				my $rp = substr($l, -($bclen+4 + $primerinfo[3]),  $primerinfo[3]);	#This calculation is OK
				my $rbc = substr($l, -($bclen+4), $bclen );
				$bc = "$lbc-$rbc";
				my $seq = substr($l, ($bclen+4 + $primerinfo[2]), -($bclen+4 + $primerinfo[3]));

#				print "$bc\t$seq\n";
#				print "$primerinfo[3]\n";

				$keep = "N" if length($seq) < 50;
				my $id = "NULL";
				$id = $vtag{$bc} if $vtag{$bc};

				$r1 .= "\t$id\t$lp\t$seq\t$rp\t$bc";
			}
			$counter++;
		}elsif($counter % 4 == 3) { #quality score line
			$fastq .= "$l\n";
			$r1 .= "\t$l";
			$counter++;
		}else{
			$fastq .= "$l\n";
			$counter++;
		}
#	if ($counter > 24){ close IN; exit;}
	}
close IN;

#WORKS
# will make a set of valid tags for the dataset of interest
sub pop_tag{
	my %tags;
	my $expt = $_[1];
	open (IN, "< $_[0]") or die "$!\n";
		while(my $l = <IN>){
			chomp $l;
			my @l = split/\t/, $l;
			if ($l !~ /BC/ && $l[5] eq $expt){
				my $rtag = reverse($l[1]); $rtag =~ tr/acgtACGT/tgcaTGCA/;
				my $tags = uc("$l[0]-$rtag");
				$tags{$tags} = "$l[2]";	#grab the sample ID for each barcode pair
			}
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
			if ($l[0] eq $_[1]){ #check for primer name
				#change redundant segments to X
				( $data[0] = $l[1] ) =~ s/\[.{2,3}\]/X/g; #replace [AC] with X
				( $data[1] = $l[2] ) =~ s/\[.{2,3}\]/X/g;
				$data[2] = length($data[0]); #left primer length
				$data[3] = length($data[1]); #right primer length
				$data[4] = scalar(split/X/, $data[0]) + $additional_mismatches; #one more mismatches than redundant positions
				$data[5] = scalar(split/X/, $data[1]) + $additional_mismatches;
				$data[6] = $l[1]; #actual primer sequence
				$data[7] = $l[2];
			}
		}
	close IN;
	return(@data)
}
