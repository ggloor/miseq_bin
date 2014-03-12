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
my $dir = "data_" . $ARGV[1];
my %groups; my %gname; my %gcount;
my $gid = 0;
open (IN, "< $ARGV[0]") or die;
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/\t/, $l; #split on z
		if (!exists $groups{$l[3]}){
			 $groups{$l[3]} = $gid;
			 $gname{$l[3]} .= "$l[0]"; #separated by @ sign
			 $gcount{$l[3]}++;
			 $gid++;
		}elsif (exists $groups{$l[3]}){
			 $gname{$l[3]} .= "$l[0]";
			 $gcount{$l[3]}++;
		}
	}
close IN;

#my @k = keys(%gcount);

# sort these based on the number of reads

open (OUTG, "> $dir/groups.txt") or die;
open (OUTN, "> $dir/reads_in_groups.txt") or die;

foreach my $k (sort { $gcount{$b} <=> $gcount{$a} } keys %gcount) {
	print OUTG ">lcl|$groups{$k}|num|$gcount{$k}\t$k\n" if $gcount{$k} > 1;
	print OUTN "$groups{$k}$gname{$k}\n" if $gcount{$k} > 1;
}

close OUTN;
close OUTG;

#foreach(@k){
#	print OUTG ">lcl|$groups{$_}|num|$gcount{$_}\t$_\n";
#	print OUTN "$groups{$_}$gname{$_}\n";
#}

