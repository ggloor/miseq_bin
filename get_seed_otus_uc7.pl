#!/usr/bin/env perl -w
use strict;
#######
# This software is Copyright 2011 Greg Gloor and is distributed under the 
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
my @otus;# = qw(OTU_0 OTU_1 OTU_2 OTU_3 OTU_4 OTU_5 OTU_6 OTU_7 OTU_8 OTU_9 OTU_10 OTU_11 OTU_12 OTU_13 OTU_14 OTU_15 OTU_16 OTU_17 OTU_18 OTU_19 OTU_20 OTU_21 OTU_22 OTU_23 OTU_24 OTU_25 OTU_26 OTU_27 OTU_28 OTU_29 OTU_30 OTU_31 OTU_32 OTU_33 OTU_34 OTU_35 OTU_36 OTU_37 OTU_38 OTU_39 OTU_40 OTU_41 OTU_42 OTU_43 OTU_44 OTU_45 OTU_46 OTU_47 OTU_48 OTU_49 OTU_50 OTU_51 OTU_52 OTU_53 OTU_54 OTU_55 OTU_56 OTU_57 OTU_58 OTU_59 OTU_61 OTU_62 OTU_63 OTU_64 OTU_66 OTU_67 OTU_69 OTU_73 OTU_74 OTU_75 OTU_76 OTU_78 OTU_86 OTU_88 OTU_91 OTU_93 OTU_95 OTU_98);

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
}

my %keep;
open (IN, "< $ARGV[0]") or die; #uclust file
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/\t/, $l;
		if ($l[0] eq "H" && exists $otu_hash{$l[1]} && $l[3] == 100.0){
		 	$keep{$l[8]} = ">$l[8]|OTU|$l[1]" if $l[7] eq ($l[2] . "M");
			#print "$otu_hash{$l[1]}\n";
		}
	}
close IN;

my $last;
open (IN, "< $ARGV[1]") or die; #groups.fa file
	while(defined(my $l = <IN>)){
		chomp $l;
		if ($l =~ /^>/){
			my @l = split/>/, $l;
			$last = $l[1];
			#print "$last\n";
		}else{
			print "$keep{$last}\n$l\n" if exists $keep{$last};
		}
	}
close IN;