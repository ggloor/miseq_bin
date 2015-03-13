#!/usr/bin/env perl -w
use strict;

#ARG 0 usearch output
#ARG 1 seed ISU sequence from usearch
#ARG 2 OTU table file
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

my %otu_hash;
my @otus;

open (IN, "< $ARGV[2]") or die "$!\n"; #otu table file
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/\t/, $l;
		if ($l =~/^Ltag/){
			my @l = split/\t/, $l;
			my $len = @l - 2;
			@otus = @l[2 .. $len];
		}
	}	
close IN;

foreach(@otus){
	my @l = split/_/, $_;
	$otu_hash{$l[1]} = "";
	#print "$l[1] \n";
} 
#exit;

my %seed_ISU; my $last;
open (IN, "< $ARGV[1]") or die; #seed ISU file from uclust 8, keep isu id and sequence
	while(my $l = <IN>){
		chomp $l;
		if ($l =~ /^>/){
			$last = "";
			my @l = split/\|/, $l;
			$last = "lcl|$l[1]";
			#print "$last\n";
			$seed_ISU{$last} = "";
		}else{
			$seed_ISU{$last} .= uc($l);
		}
	}
close IN;
#exit;

open (IN, "< $ARGV[0]") or die; #uclust file
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/\t/, $l;
		my @query = split/\|/, $l[8];
		my @db = split/\|/, $l[9];
		if ($l[0] eq "H" && exists $otu_hash{$l[1]}){
		 	#$keep{$l[8]} = ">$l[8]|OTU|$l[1]\n$seed_ISU{$l[9]\n");
		 	print ">$l[8]|OTU|$l[1]\n$seed_ISU{$l[9]}\n" if   $query[1] == $db[1];
			#print "$query[1] $db[1]\n" if $query[1] == $db[1];
			#print "$otu_hash{$l[1]}\n";
		}
	}
close IN;

