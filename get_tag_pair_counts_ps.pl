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
#make output files of ISU and OTU read counts per tag pair

#open the final mapped otu isu read file

my $mincount = 1;
$mincount = $ARGV[1] if exists $ARGV[1];

my $dir = "analysis_" . $ARGV[2];

#both keyed by LTAG-RTAG
my %OTUtaghash; #hash of arrays holding OTU counts
my %ISUtaghash; #hash arrays holding ISU counts
my %OTUtagtotal = my %ISUtagtotal;
my $ISUmax = my $OTUmax = 0;

open (IN, "< $ARGV[0]") or die;
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/\t/, $l;
		my @ll = split/\|/, $l[0]; #get the OTU and ISU numbers
		
		#left tag at position 1, right tag at position 5
		if ($ll[2] =~ /\d+/ && $ll[4] =~ /\d+/){
		$ISUmax = $ll[2] if $ll[2] > $ISUmax;
		#print "$ISUmax " if $ll[4] == $ISUmax;#find the largest OTU and ISU id numbers
		$OTUmax = $ll[4] if $ll[4] > $OTUmax;
		my $tagpr = "$l[1]-$l[5]";
		${ $OTUtaghash{$tagpr} }[$ll[4]]++;
		$OTUtagtotal{$tagpr}++;
		${ $ISUtaghash{$tagpr} }[$ll[2]]++;
		$ISUtagtotal{$tagpr}++;
		}
	}
close IN;
#exit;
my $nbadISU = 0;
my $nbadOTU = 0;

get_otu_info();
get_isu_info();

print "there are $nbadISU ISU and $nbadOTU OTU reads that are present at an abundance of <= than $mincount% in any sample.\nThese data are grouped together in the rem column.\n";
print "If the rem column contains a large fraction of the reads, try decreasing the cutoff to 0.1.\nThis can occur when only a small number of samples are analyzed";

######
sub get_otu_info{
	my @k = keys(%OTUtaghash);

	#first build a hash of OTUs that have more than 1% of the total count in any row
	my %validOTU;
	foreach(@k){
		for (my $i =0; $i <= $OTUmax; $i++){
			my $val = 0;
			$val = ( ( ${ $OTUtaghash{$_} }[$i] /  $OTUtagtotal{$_} ) * 100) if exists ${ $OTUtaghash{$_} }[$i];
			#make a valid OTU identifier if the value is greater than the minimal percentage count
			$validOTU{$i} = "" if $val > $mincount;
			#print "$val " if $val > $mincount;
		}
	}
	#populate the OTU header
	my $OTU_data = "";
	$OTU_data .= "Ltag-Rtag\ttotal";
	for (my $i =0; $i <= $OTUmax; $i++){
		$OTU_data .= "\tOTU_$i" if exists $validOTU{$i};
	}
	$OTU_data .= "\trem\n";
	
	#now print out the groups
	foreach(@k){
		$OTU_data .= "$_\t$OTUtagtotal{$_}";
		my $rem = 0;
		for (my $i =0; $i <= $OTUmax; $i++){
			my $val = 0;
			$val = ${ $OTUtaghash{$_} }[$i] if exists ${ $OTUtaghash{$_} }[$i];
			$nbadOTU += $val if !exists $validOTU{$i}; # <= $mincount;
			$rem += $val if !exists $validOTU{$i}; # <= $mincount;
			$OTU_data .= "\t$val" if exists $validOTU{$i}#;  > $mincount;
		}
		$OTU_data .= "\t$rem\n";
	}
	open (OUT, "> $dir/OTU_tag_mapped.txt") or die;
	print OUT $OTU_data;
	close OUT;
}


sub get_isu_info{
	my @k = keys(%ISUtaghash);

	#first build a hash of ISUs that have more than 1% of the total count in any row
	my %validISU;
	foreach(@k){
		for (my $i =0; $i <= $ISUmax; $i++){
			my $val = 0;
			$val = ( ( ${ $ISUtaghash{$_} }[$i] /  $ISUtagtotal{$_} ) * 100) if exists ${ $ISUtaghash{$_} }[$i];
			#make a valid ISU identifier if the value is greater than the minimal count
			$validISU{$i} = "" if $val > $mincount;
			#print "$val " if $val > $mincount;
		}
	}
	#populate the ISU header
	my $ISU_data = "";
	$ISU_data .= "Ltag-Rtag\ttotal";
	for (my $i =0; $i <= $ISUmax; $i++){
		$ISU_data .= "\tISU_$i" if exists $validISU{$i};
	}
	$ISU_data .= "\trem\n";
	
	#now print out the groups
	foreach(@k){
		$ISU_data .= "$_\t$ISUtagtotal{$_}";
		my $rem = 0;
		for (my $i =0; $i <= $ISUmax; $i++){
			my $val = 0;
			$val = ${ $ISUtaghash{$_} }[$i] if exists ${ $ISUtaghash{$_} }[$i];
			$nbadISU += $val if !exists $validISU{$i}; # <= $mincount;
			$rem += $val if !exists $validISU{$i}; # <= $mincount;
			$ISU_data .= "\t$val" if exists $validISU{$i}#;  > $mincount;
		}
		$ISU_data .= "\t$rem\n";
	}
	open (OUT, "> $dir/ISU_tag_mapped.txt") or die;
	print OUT $ISU_data;
	close OUT;
}




