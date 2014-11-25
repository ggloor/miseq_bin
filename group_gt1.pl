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
# the objective is to make a fasta file of ISUs in rank abundance order
# and a lookup table of ISU_ids and read identifiers
my $dir = "data_" . $ARGV[1];
my %groups; my %gname; my %gcount;
my $gid = 0; #trivial ISU_id
open (IN, "< $ARGV[0]") or die; # rekeyedtabbedfile.txt file is the input. 
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/\t/, $l; #split on z
		if (!exists $groups{$l[3]}){ #if the group has not been seen before
			 $groups{$l[3]} = $gid; #hash table containing only group ID, keyed by unique sequence
			 $gname{$l[3]} .= "$l[0]"; # concatenate sequence identifiers, separated by @ sign
			 $gcount{$l[3]}++; # count the number of identifiers
			 $gid++; #increment ISU_id
		}elsif (exists $groups{$l[3]}){
			 $gname{$l[3]} .= "$l[0]";
			 $gcount{$l[3]}++;
		}
	}
close IN;


# sort these based on the number of reads
open (OUTG, "> $dir/groups.txt") or die;
open (OUTN, "> $dir/reads_in_groups.txt") or die;

#for each key in %gcount, keys in all three hashes have to occur if in one
#sort keys by the abundance in hash %gcount
foreach my $k (sort { $gcount{$b} <=> $gcount{$a} } keys %gcount) {
	print OUTG ">lcl|$groups{$k}|num|$gcount{$k}\t$k\n" if $gcount{$k} > 1; #would be best to have this as a flag with default 1
	print OUTN "$groups{$k}$gname{$k}\n" if $gcount{$k} > 1;
}

close OUTN;
close OUTG;


